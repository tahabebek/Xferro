import Foundation

class Index {
    struct Entry {
        var git_entry: git_index_entry
        init(git_entry: git_index_entry) {
            self.git_entry = git_entry
        }

        var skipWorktree: Bool {
            get {
                return self.git_entry.flags_extended & UInt16(GIT_INDEX_ENTRY_SKIP_WORKTREE.rawValue) > 0
            }
            set {
                if newValue {
                    self.git_entry.flags_extended |= UInt16(GIT_INDEX_ENTRY_SKIP_WORKTREE.rawValue)
                } else {
                    self.git_entry.flags_extended &= ~UInt16(GIT_INDEX_ENTRY_SKIP_WORKTREE.rawValue)
                }
            }
        }

        var oid: OID {
            OID(self.git_entry.id)
        }
    }

    var git_index: OpaquePointer
    private var lock: NSRecursiveLock
    private let pointer: OpaquePointer

    init(git_index: OpaquePointer, lock: NSRecursiveLock) {
        self.git_index = git_index
        self.lock = lock
        self.pointer = git_index
    }

    var entryCount: Int {
        git_index_entrycount(git_index)
    }

    var hasConflicts: Bool {
        git_index_has_conflicts(git_index) != 0
    }

//    var conflicts: AnySequence<ConflictEntry> {
//        AnySequence {
//            ConflictIterator(index: self.index)
//        }
//    }

    func entry(atIndex index: Int) -> Index.Entry! {
        switch index {
        case 0..<entryCount:
            guard let entry = git_index_get_byindex(git_index, index) else { return nil }
            return Entry(git_entry: entry.pointee)
        default:
            return nil
        }
    }

    func entry(at path: String) -> Index.Entry? {
        var position: Int = 0
        guard git_index_find(&position, git_index, path) == 0,
              let entry = git_index_get_byindex(git_index, position)
        else { return nil }

        return Entry(git_entry: entry.pointee)
    }

    deinit {
        git_index_free(self.git_index)
    }

    func add(entry: Entry) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var git_entry = entry.git_entry
        let result = git_index_add(self.git_index, &git_entry)
        if result == GIT_OK.rawValue {
            return .success(())
        }
        return .failure(NSError(gitError: result, pointOfFailure: "git_index_add"))
    }

    func add(data: Data, path: String)
    {
        let result = data.withUnsafeBytes {
            (bytes: UnsafeRawBufferPointer) -> Int32 in
            var entry = git_index_entry()

            return path.withCString {
                (path) in
                entry.path = path
                entry.mode = GIT_FILEMODE_BLOB.rawValue
                return git_index_add_frombuffer(pointer, &entry, bytes.baseAddress, data.count)
            }
        }

        guard result == GIT_OK.rawValue else {
            fatalError()
        }
    }

    @discardableResult
    func save() -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let result = git_index_write(self.git_index)
        if result == GIT_OK.rawValue {
            return .success(())
        }
        return .failure(NSError(gitError: result, pointOfFailure: "git_index_write"))
    }

    func entry(
        by path: String,
        stage: Bool,
        block: (inout Entry) -> Result<Bool, NSError>
    ) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        guard let result = path.withCString({
            git_index_get_bypath(self.git_index, $0, stage ? 1 : 0)
        }) else {
            return .failure(NSError(gitError: GIT_ENOTFOUND.rawValue, pointOfFailure: "git_index_get_bypath"))
        }
        var entry = Entry(git_entry: result.pointee)
        return block(&entry).flatMap { changed in
            if !changed { return .success(()) }
            return self.add(entry: entry).flatMap {
                self.save()
            }
        }
    }

    func refresh() throws {
        try RepoError.throwIfGitError(git_index_read(git_index, 1))
    }
}

extension Repository {
    func index() -> Result<Index, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var git_index: OpaquePointer?
        let result = git_repository_index(&git_index, self.pointer)
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_repository_index"))
        }
        return .success(Index(git_index: git_index!, lock: lock))
    }

    func writeTree(git_index: OpaquePointer) throws -> Tree {
        var treeOID = git_oid()
        let result = git_index_write_tree(&treeOID, git_index)

        try RepoError.throwIfGitError(result)
        let tree = object(OID(treeOID)).mustSucceed(gitDir) as? Tree

        guard let tree else {
            throw RepoError.unexpected("Tree not found")
        }

        return tree
    }
}
