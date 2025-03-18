//
//  Repository.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

class Repository: Identifiable {
    let id = UUID()
    static let staticLock = NSRecursiveLock()
    let lock = NSRecursiveLock()
    let queue: TaskQueue

    /// The underlying libgit2 `git_repository` object.
    let pointer: OpaquePointer

    // MARK: - Initializers

    /// Create an instance with a libgit2 `git_repository` object.
    ///
    /// The Repository assumes ownership of the `git_repository` object.
    init(_ pointer: OpaquePointer) {
        self.pointer = pointer
        self.queue = TaskQueue(id: Self.taskQueueID(path: id.uuidString))
    }

    static func taskQueueID(path: String) -> String
    {
        let identifier = Bundle.main.bundleIdentifier ?? "com.xferro"

        return "\(identifier).\(path)"
    }

    deinit {
//        print("deinit repository \(gitDir)")
        git_repository_free(pointer)
    }

    /**
     * Get the path of this repository
     *
     * This is the path of the `.git` folder for normal repositories,
     * or of the repository itself for bare repositories.
     */
    lazy var gitDir: URL = {
        let path = git_repository_path(pointer)
        let result = path.map { URL(fileURLWithPath: String(validatingCString: $0)!, isDirectory: true) }
        guard let result else {
            fatalError(.impossible)
        }
        return result
    }()

    /// The URL of the repository's working directory, or `nil` if the
    /// repository is bare.
    /// (*update, bare repos are not supported yet*
    lazy var workDir: URL = {
        let path = git_repository_workdir(pointer)
        let result = path.map { URL(fileURLWithPath: String(validatingCString: $0)!, isDirectory: true) }
        guard let result else {
            fatalError(.unsupported)
        }
        return result
    }()

    /**
     * Get the path of the shared common directory for this repository.
     *
     * If the repository is bare, it is the root directory for the repository.
     * If the repository is a worktree, it is the parent repo's gitdir.
     * Otherwise, it is the gitdir.
     */
    lazy var commonDir: URL? = {
        let path = git_repository_commondir(pointer)
        return path.map { URL(fileURLWithPath: String(validatingCString: $0)!, isDirectory: true) }
    }()

    // MARK: - Object Lookups

    /// Load a libgit2 object and transform it to something else.
    ///
    /// oid       - The OID of the object to look up.
    /// type      - The type of the object to look up.
    /// transform - A function that takes the libgit2 object and transforms it
    ///             into something else.
    ///
    /// Returns the result of calling `transform` or an error if the object
    /// cannot be loaded.
    func withGitObject<T>(
        _ oid: OID,
        type: git_object_t,
        staticLock: NSRecursiveLock? = nil,
        transform: (OpaquePointer) -> Result<T, NSError>
    ) -> Result<T, NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        var pointer: OpaquePointer? = nil
        var git_oid = oid.oid
        let result = git_object_lookup_prefix(&pointer, self.pointer, &git_oid, oid.length, type)

        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_object_lookup_prefix"))
        }

        let value = transform(pointer!)
        git_object_free(pointer)
        if let staticLock {
            staticLock.unlock()
        } else {
            lock.unlock()
        }
        return value
    }

    func withGitObject<T>(
        _ oid: OID,
        type: git_object_t,
        staticLock: NSRecursiveLock? = nil,
        transform: (OpaquePointer) -> T)
    -> Result<T, NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        let result = withGitObject(oid, type: type, staticLock: staticLock) { Result.success(transform($0)) }

        if let staticLock {
            staticLock.unlock()
        } else {
            lock.unlock()
        }
        return result
    }

    func withGitObjects<T>(
        _ oids: [OID],
        type: git_object_t,
        staticLock: NSRecursiveLock? = nil,
        transform: ([OpaquePointer]) -> Result<T, NSError>
    ) -> Result<T, NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        var pointers = [OpaquePointer]()
        defer {
            for pointer in pointers {
                git_object_free(pointer)
            }
        }

        for oid in oids {
            var pointer: OpaquePointer? = nil
            var oid = oid.oid
            let result = git_object_lookup(&pointer, self.pointer, &oid, type)

            guard result == GIT_OK.rawValue else {
                let result: Result<T, NSError> = Result.failure(
                    NSError(
                        gitError: result,
                        pointOfFailure: "git_object_lookup"
                    )
                )
                if let staticLock {
                    staticLock.unlock()
                } else {
                    lock.unlock()
                }
                return result
            }

            pointers.append(pointer!)
        }

        let result = transform(pointers)
        if let staticLock {
            staticLock.unlock()
        } else {
            lock.unlock()
        }
        return result
    }

    /// Loads the object with the given OID.
    ///
    /// oid - The OID of the blob to look up.
    ///
    /// Returns a `Blob`, `Commit`, `Tag`, or `Tree` if one exists, or an error.
    func object(_ oid: OID, staticLock: NSRecursiveLock? = nil) -> Result<ObjectType, NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        let result = withGitObject(oid, type: GIT_OBJECT_ANY, staticLock: staticLock) { object in
            return self.object(from: object, staticLock: staticLock)
        }
        if let staticLock {
            staticLock.unlock()
        } else {
            lock.unlock()
        }
        return result
    }

    /// Loads the referenced object from the pointer.
    ///
    /// pointer - A pointer to an object.
    ///
    /// Returns the object if it exists, or an error.
    func object<T>(from pointer: PointerTo<T>, staticLock: NSRecursiveLock? = nil) -> Result<T, NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        let result = withGitObject(pointer.oid, type: pointer.type.git_type, staticLock: staticLock) {
            T($0, lock: lock)
        }
        if let staticLock {
            staticLock.unlock()
        } else {
            lock.unlock()
        }
        return result
    }

    /// Loads the referenced object from the pointer.
    ///
    /// pointer - A pointer to an object.
    ///
    /// Returns the object if it exists, or an error.
    func object(from pointer: Pointer, staticLock: NSRecursiveLock? = nil) -> Result<ObjectType, NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        let result =
        switch pointer {
        case let .blob(oid):
            blob(oid, staticLock: staticLock).map { $0 as ObjectType }
        case let .commit(oid):
            commit(oid, staticLock: staticLock).map { $0 as ObjectType }
        case let .tag(oid):
            tag(oid, staticLock: staticLock).map { $0 as ObjectType }
        case let .tree(oid):
            tree(oid, staticLock: staticLock).map { $0 as ObjectType }
        }
        if let staticLock {
            staticLock.unlock()
        } else {
            lock.unlock()
        }
        return result
    }

    /// Loads the referenced object from the git_object.
    ///
    /// pointer - A pointer to an object.
    ///
    /// Returns the object if it exists, or an error.
    func object(from object: OpaquePointer, staticLock: NSRecursiveLock? = nil) -> Result<ObjectType, NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        let type = git_object_type(object)
        let result: Result<ObjectType, NSError>
        if type == Blob.type.git_type {
            result = .success(Blob(object, lock: staticLock ?? lock))
        } else if type == Commit.type.git_type {
            result =  .success(Commit(object, lock: staticLock ?? lock))
        } else if type == Tag.type.git_type {
            result =  .success(Tag(object, lock: staticLock ?? lock))
        } else if type == Tree.type.git_type {
            result =  .success(Tree(object, lock: staticLock ?? lock))
        } else {
            let error = NSError(domain: "org.libgit2.SwiftGit2",
                                code: 1,
                                userInfo: [NSLocalizedDescriptionKey: "Unrecognized git_object_t '\(type)'."])
            result =  .failure(error)
        }
        if let staticLock {
            staticLock.unlock()
        } else {
            lock.unlock()
        }
        return result
    }

    /// Loads the blob with the given OID.
    ///
    /// oid - The OID of the blob to look up.
    ///
    /// Returns the blob if it exists, or an error.
    func blob(_ oid: OID, staticLock: NSRecursiveLock? = nil) -> Result<Blob, NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        let result = withGitObject(oid, type: GIT_OBJECT_BLOB, staticLock: staticLock) {
            Blob($0, lock: staticLock ?? lock)
        }
        if let staticLock {
            staticLock.unlock()
        } else {
            lock.unlock()
        }
        return result
    }

    /// Loads the tree with the given OID.
    ///
    /// oid - The OID of the tree to look up.
    ///
    /// Returns the tree if it exists, or an error.
    func tree(_ oid: OID, staticLock: NSRecursiveLock? = nil) -> Result<Tree, NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        let result = withGitObject(oid, type: GIT_OBJECT_TREE, staticLock: staticLock) {
            Tree($0, lock: staticLock ?? lock)
        }

        if let staticLock {
            staticLock.unlock()
        } else {
            lock.unlock()
        }
        return result
    }

    // MARK: - Status

    func status(
        options: StatusOptions? = nil,
        staticLock: NSRecursiveLock? = nil
    ) -> Result<[StatusEntry], NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        let options = options ?? .includeUntracked
        var returnArray = [StatusEntry]()

        // Do this because GIT_STATUS_OPTIONS_INIT is unavailable in swift
        let statusOptionsPointer = UnsafeMutablePointer<git_status_options>.allocate(capacity: 1)
        let optionsResult = git_status_options_init(statusOptionsPointer, UInt32(GIT_STATUS_OPTIONS_VERSION))
        guard optionsResult == GIT_OK.rawValue else {
            let result: Result<[StatusEntry], NSError> = .failure(
                NSError(gitError: optionsResult, pointOfFailure: "git_status_init_options")
            )
            if let staticLock {
                staticLock.unlock()
            } else {
                lock.unlock()
            }
            return result
        }
        var opts = statusOptionsPointer.move()
        opts.flags = options.rawValue
        opts.rename_threshold = 50
        statusOptionsPointer.deallocate()

        var unsafeStatus: OpaquePointer? = nil
        defer { git_status_list_free(unsafeStatus) }
        let statusResult = git_status_list_new(&unsafeStatus, pointer, &opts)
        guard statusResult == GIT_OK.rawValue, let unwrapStatusResult = unsafeStatus else {
            let result: Result<[StatusEntry], NSError> = .failure(
                NSError(gitError: statusResult, pointOfFailure: "git_status_list_new")
            )
            if let staticLock {
                staticLock.unlock()
            } else {
                lock.unlock()
            }
            return result
        }

        let count = git_status_list_entrycount(unwrapStatusResult)

        for i in 0..<count {
            let s = git_status_byindex(unwrapStatusResult, i)
            if s?.pointee.status.rawValue == GIT_STATUS_CURRENT.rawValue {
                continue
            }

            let statusEntry = StatusEntry(from: s!.pointee, workDir: workDir)
            returnArray.append(statusEntry)
        }

        let result: Result<[StatusEntry], NSError> = .success(returnArray)
        if let staticLock {
            staticLock.unlock()
        } else {
            lock.unlock()
        }
        return result
    }

    func status(for path: String, staticLock: NSRecursiveLock? = nil) -> Result<Diff.Status?, NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        var flags: UInt32 = 0
        let result = path.withCString { cpath in
            git_status_file(&flags, self.pointer, cpath)
        }
        if result == GIT_ENOTFOUND.rawValue {
            let result: Result<Diff.Status?, NSError> = .success(nil)
            if let staticLock {
                staticLock.unlock()
            } else {
                lock.unlock()
            }
            return result
        }
        guard result == GIT_OK.rawValue else {
            let result: Result<Diff.Status?, NSError> = .failure(
                NSError(
                    gitError: result,
                    pointOfFailure: "git_status_file"
                )
            )
            if let staticLock {
                staticLock.unlock()
            } else {
                lock.unlock()
            }
            return result
        }
        let status: Result<Diff.Status?, NSError>  = .success(Diff.Status(rawValue: flags))
        if let staticLock {
            staticLock.unlock()
        } else {
            lock.unlock()
        }
        return status
    }

    // MARK: - Validity/Existence Check

    /// - returns: `.success(true)` iff there is a git repository at `url`,
    ///   `.success(false)` if there isn't,
    ///   and a `.failure` if there's been an error.
    static func isValid(url: URL) -> Result<Bool, NSError> {
        staticLock.lock()
        defer { staticLock.unlock() }
        var pointer: OpaquePointer?

        let result = url.withUnsafeFileSystemRepresentation {
            git_repository_open_ext(&pointer, $0, GIT_REPOSITORY_OPEN_NO_SEARCH.rawValue, nil)
        }

        switch result {
        case GIT_ENOTFOUND.rawValue:
            return .success(false)
        case GIT_OK.rawValue:
            return .success(true)
        default:
            return .failure(NSError(gitError: result, pointOfFailure: "git_repository_open_ext"))
        }
    }

    /*
     * The tag name will be checked for validity. You must avoid
     * the characters '~', '^', ':', '\\', '?', '[', and '*', and the
     * sequences ".." and "@{" which have special meaning to revparse.
     */
    func checkValid(_ refname: String, staticLock: NSRecursiveLock? = nil) -> Bool {
        if let staticLock {
            staticLock.lock()
        } else {
            lock.lock()
        }
        var status: Int32 = 0
        let result = git_reference_name_is_valid(&status, refname)
        if let staticLock {
            staticLock.unlock()
        } else {
            lock.unlock()
        }
        guard result == GIT_OK.rawValue else {
            return false
        }
        return status == 1
    }

    static func isGitRepository(url: URL) -> Result<Bool, NSError> {
        staticLock.lock()
        defer { staticLock.unlock() }
        var repo: OpaquePointer?
        let result = url.withUnsafeFileSystemRepresentation {
            git_repository_open(
                &repo,
                $0
            );
        }


        if (repo != nil) {
            git_repository_free(repo);
        }

        switch result {
        case GIT_ENOTFOUND.rawValue:
            return .success(false)
        case GIT_OK.rawValue:
            return .success(true)
        default:
            return .failure(NSError(gitError: result, pointOfFailure: "git_repository_open"))
        }
    }


    static func at(_ url: URL) -> Result<Repository, NSError> {
        staticLock.lock()
        defer { staticLock.unlock() }
        var pointer: OpaquePointer? = nil
        let result = url.withUnsafeFileSystemRepresentation {
            git_repository_open(&pointer, $0)
        }

        guard result == GIT_OK.rawValue else {
            let error = NSError(gitError: result, pointOfFailure: "git_repository_open")
            print(error.localizedDescription)
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_open"))
        }

        let repository = Repository(pointer!)
        return Result.success(repository)
    }

    static func create(at url: URL) -> Result<Repository, NSError> {
        staticLock.lock()
        defer { staticLock.unlock() }
        var pointer: OpaquePointer? = nil
        let result = url.withUnsafeFileSystemRepresentation {
            git_repository_init(&pointer, $0, 0)
        }

        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_init"))
        }

        let repository = Repository(pointer!)
        return Result.success(repository)
    }

    static func discover(_ path: String, acrossFS: Bool = false, ceiling: [String] = []) -> Result<Repository, NSError> {
        staticLock.lock()
        defer { staticLock.unlock() }
        var buf = git_buf(ptr: nil, reserved: 0, size: 0)
        defer {
            git_buf_dispose(&buf)
        }
        let result = path.withCString { start_path in
            return ceiling.joined(separator: ":").withCString { ceiling_dirs in
                return git_repository_discover(&buf, start_path, acrossFS ? 1 : 0, ceiling_dirs)
            }
        }
        guard result == GIT_OK.rawValue,
              let root = String(bytes: buf.ptr, count: buf.size) else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_discover"))
        }
        return Repository.at(URL(fileURLWithPath: root))
    }
}

extension Array {
    func aggregateResult<Value, Error>() -> Result<[Value], Error> where Element == Result<Value, Error> {
        var values: [Value] = []
        for result in self {
            switch result {
            case .success(let value):
                values.append(value)
            case .failure(let error):
                return .failure(error)
            }
        }
        return .success(values)
    }
}
