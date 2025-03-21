//
//  Remote.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

/// A remote in a git repository.

final class Remote {
    let remote: OpaquePointer

    var name: String? {
        guard let name = git_remote_name(remote) else { return nil }
        return String(cString: name)
    }

    var urlString: String? {
        guard let url = git_remote_url(remote) else { return nil }
        return String(cString: url)
    }

    var pushURLString: String? {
        guard let url = git_remote_pushurl(remote)
        else { return nil }
        return String(cString: url)
    }

    var refSpecs: AnyCollection<GitRefSpec> {
        AnyCollection(RefSpecCollection(remote: self))
    }

    init?(name: String, repository: OpaquePointer) {
        guard let remote = try? OpaquePointer.from({
            git_remote_lookup(&$0, repository, name) })
        else { return nil }
        self.remote = remote
    }

    init(remote: OpaquePointer) {
        self.remote = remote
    }

    init?(url: URL) {
        guard let remote = try? OpaquePointer.from({
            git_remote_create_detached(&$0, url.absoluteString)
        })
        else { return nil }
        self.remote = remote
    }

    deinit {
        git_remote_free(remote)
    }

    func rename(_ name: String) throws {
        guard let oldName = git_remote_name(remote) else {
            throw RepoError.unexpected("Old name not found")
        }

        guard let owner = git_remote_owner(remote) else {
            throw RepoError.unexpected("Owner not found")
        }

        let problems = UnsafeMutablePointer<git_strarray>.allocate(capacity: 1)
        defer {
            problems.deallocate()
        }

        problems.pointee = git_strarray()

        let result = git_remote_rename(problems, owner, oldName, name)
        let resultCode = git_error_code(rawValue: result)

        defer {
            git_strarray_free(problems)
        }
        switch resultCode {
        case GIT_EINVALIDSPEC:
            throw RepoError.invalidName(name)
        case GIT_EEXISTS:
            throw RepoError.duplicateName
        case GIT_OK:
            break
        default:
            throw RepoError(gitCode: resultCode)
        }
    }

    func updateURLString(_ URLString: String?) throws {
        guard let name = git_remote_name(remote) else {
            throw RepoError.unexpected("Old name not found")
        }

        guard let owner = git_remote_owner(remote) else {
            throw RepoError.unexpected("Owner not found")
        }
        let result = git_remote_set_url(owner, name, URLString)

        if result == GIT_EINVALIDSPEC.rawValue {
            throw RepoError.invalidName(URLString ?? "")
        } else {
            try RepoError.throwIfGitError(result)
        }
    }

    func updatePushURLString(_ URLString: String?) throws {
        guard let name = git_remote_name(remote) else {
            throw RepoError.unexpected("Old name not found")
        }

        guard let owner = git_remote_owner(remote) else {
            throw RepoError.unexpected("Owner not found")
        }
        let result = git_remote_set_pushurl(owner, name, URLString)

        if result == GIT_EINVALIDSPEC.rawValue {
            throw RepoError.invalidName(URLString ?? "")
        } else {
            try RepoError.throwIfGitError(result)
        }
    }

    func withConnection<T>(
        direction: RemoteConnectionDirection,
        callbacks: RemoteCallbacks,
        action: (any ConnectedRemote) throws -> T
    ) throws -> T {
        var result: Int32
        result = git_remote_callbacks.withCallbacks(callbacks) {
            (gitCallbacks) in
            withUnsafePointer(to: gitCallbacks) {
                (callbacksPtr) in
                git_remote_connect(remote, direction.gitDirection, callbacksPtr, nil, nil)
            }
        }

        try RepoError.throwIfGitError(result)
        defer {
            git_remote_disconnect(remote)
        }
        return try action(GitConnectedRemote(remote))
    }

    var url: URL? { urlString.flatMap { URL(string: $0) } }
    var pushURL: URL? { pushURLString.flatMap { URL(string: $0) } }

    func updateURL(_ url: URL) throws {
        try updateURLString(url.absoluteString)
    }

    func updatePushURL(_ url: URL) throws {
        try updatePushURLString(url.absoluteString)
    }
}

extension Remote {
    struct RefSpecCollection: Collection {
        let remote: Remote

        var count: Int { git_remote_refspec_count(remote.remote) }

        func makeIterator() -> RefSpecIterator {
            RefSpecIterator(remote: remote)
        }

        subscript(position: Int) -> GitRefSpec {
            GitRefSpec(refSpec: git_remote_get_refspec(remote.remote, position))
        }

        var startIndex: Int { 0 }
        var endIndex: Int { count }

        func index(after i: Int) -> Int {
            i + 1
        }
    }

    struct RefSpecIterator: IteratorProtocol {
        var index: Int
        let remote: Remote

        init(remote: Remote) {
            self.index = 0
            self.remote = remote
        }

        mutating func next() -> GitRefSpec? {
            guard index < git_remote_refspec_count(remote.remote) else { return nil }

            defer {
                index += 1
            }
            return GitRefSpec(refSpec: git_remote_get_refspec(remote.remote, index))
        }
    }
}

struct RemoteHead {
    let local: Bool
    let oid: OID
    let localOID: OID
    let name: String
    let symrefTarget: String

    init(_ head: git_remote_head) {
        self.local = head.local == 0 ? false : true
        self.oid = OID(head.oid)
        self.localOID = OID(head.loid)
        self.name = String(cString: head.name)
        self.symrefTarget = head.symref_target.map { String(cString: $0) } ?? ""
    }
}

class GitConnectedRemote: ConnectedRemote {
    let remote: OpaquePointer

    var defaultBranch: String? {
        var buf = git_buf()
        let result = git_remote_default_branch(&buf, remote)
        guard result == GIT_OK.rawValue
        else { return nil }
        defer {
            git_buf_free(&buf)
        }

        return String(gitBuffer: buf)
    }

    init(_ remote: OpaquePointer) {
        self.remote = remote
    }

    func referenceAdvertisements() throws -> [RemoteHead] {
        var size: size_t = 0
        let heads = try UnsafeMutablePointer.from {
            git_remote_ls(&$0, &size, remote)
        }

        return (0..<size).compactMap {
            heads.advanced(by: $0).pointee.flatMap({ RemoteHead($0.pointee) })
        }
    }
}
enum RemoteConnectionDirection: Sendable {
    case push
    case fetch
}

extension RemoteConnectionDirection {
    init(gitDirection: git_direction) {
        switch gitDirection {
        case GIT_DIRECTION_FETCH:
            self = .fetch
        default:
            self = .push
        }
    }

    var gitDirection: git_direction {
        switch self {
        case .push:
            return GIT_DIRECTION_PUSH
        case .fetch:
            return GIT_DIRECTION_FETCH
        }
    }
}

protocol ConnectedRemote: AnyObject {
    var defaultBranch: String? { get }
    func referenceAdvertisements() throws -> [RemoteHead]
}

struct PushTransferProgress: Sendable {
    let current, total: UInt32
    let bytes: size_t
}

struct RemoteCallbacks {
    typealias PasswordBlock = () -> (String, String)?
    typealias DownloadProgressBlock = (any TransferProgress) -> Bool
    typealias UploadProgressBlock = (PushTransferProgress) -> Bool
    typealias SidebandMessageBlock = (String) -> Bool

    /// Callback for getting the user and password when they could not be
    /// discovered automatically
    var passwordBlock: PasswordBlock? = nil
    /// Fetch progress. Return false to stop the operation
    var downloadProgress: DownloadProgressBlock? = nil
    /// Push progress. Return false to stop the operation
    var uploadProgress: UploadProgressBlock? = nil
    /// Message from the server
    var sidebandMessage: SidebandMessageBlock? = nil
}

protocol TransferProgress: Sendable {
    var totalObjects: UInt32 { get }
    var indexedObjects: UInt32 { get }
    var receivedObjects: UInt32 { get }
    var localObjects: UInt32 { get }
    var totalDeltas: UInt32 { get }
    var indexedDeltas: UInt32 { get }
    var receivedBytes: Int { get }
}

extension TransferProgress {
    var progress: Float { Float(receivedObjects) / Float(totalObjects) }
}
