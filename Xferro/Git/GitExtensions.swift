//
//  GitExtensions.swift
//  Xferro
//
//  Created by Taha Bebek on 3/14/25.
//

import Foundation

extension git_index_entry {
    /// The stage value is stored in certain bits of the `flags` field.
    var stage: UInt16 {
        get {
            (flags & UInt16(GIT_INDEX_ENTRY_STAGEMASK)) >> GIT_INDEX_ENTRY_STAGESHIFT
        }
        set {
            let cleared = flags & ~UInt16(GIT_INDEX_ENTRY_STAGEMASK)
            flags = cleared | ((newValue & 0x03) << UInt16(GIT_INDEX_ENTRY_STAGESHIFT))
        }
    }
}

fileprivate extension RemoteCallbacks {
    static func fromPayload(_ payload: UnsafeMutableRawPointer?)
    -> UnsafeMutablePointer<RemoteCallbacks>? {
        return payload?.bindMemory(to: RemoteCallbacks.self, capacity: 1)
    }
}


extension git_remote_callbacks {
    enum Callbacks {
        private static func sshKeyPaths() -> [String] {
            let manager = FileManager.default
            let sshDirectory = manager.homeDirectoryForCurrentUser
                .appendingPathComponent(".ssh")
            var result: [String] = []
            guard let enumerator = manager.enumerator(at: sshDirectory,
                                                      includingPropertiesForKeys: nil)
            else { return result }
            let suffixes = ["_rsa", "_dsa", "_ecdsa", "_ed25519"]

            enumerator.skipDescendants()
            while let url = enumerator.nextObject() as? URL {
                let name = url.lastPathComponent
                guard suffixes.contains(where: { name.hasSuffix($0) }),
                      manager.fileExists(atPath: url.appendingPathExtension("pub").path)
                else { continue }

                result.append(url.path)
            }

            return result
        }

        private static var retryCount = 0

        static func resetAuthAttempts() {
            retryCount = 0
        }
        
        static let credentials: git_cred_acquire_cb = { (cred, urlCString, userCString, allowed, payload) in
            guard let callbacks = RemoteCallbacks.fromPayload(payload)
            else { return -1 }
            let allowed = git_credential_t(allowed)
            let username = userCString.map { String(cString: $0) } ?? "unknown"
            let url = urlCString.map { String(cString: $0) } ?? "unknown"
            
            // Track number of auth attempts for this URL
            // If we've been called too many times for the same credential, break the loop
            if retryCount > 1 {
                retryCount = 0
                return GIT_EAUTH.rawValue
            }
            retryCount += 1


            // Try to authenticate with SSH key from agent
            if allowed.contains(GIT_CREDENTIAL_SSH_KEY) {
                let sshAgentResult = git_cred_ssh_key_from_agent(cred, userCString)

                if sshAgentResult == 0 {
                    return 0
                } else {
                    let error = git_error_last()
                    let errorMessage = error?.pointee.message.flatMap { String(cString: $0) } ?? "Unknown error"
                }

                // Fallback to direct key files
                var result: Int32 = 1
                for path in sshKeyPaths() {
                    let publicPath = path.appending(".pub")

                    result = git_cred_ssh_key_new(cred, userCString, publicPath, path, "")
                    if result == 0 {
                        return 0
                    } else {
                        let error = git_error_last()
                        let errorMessage = error?.pointee.message.flatMap { String(cString: $0) } ?? "Unknown error"
                    }
                }
            }

            return -1
        }

        static let transferProgress: git_transfer_progress_cb = {
            (stats, payload) in
            guard let callbacks = RemoteCallbacks.fromPayload(payload),
                  let progress = stats?.pointee
            else { return -1 }
            let transferProgress = GitTransferProgress(gitProgress: progress)

            return callbacks.pointee.downloadProgress!(transferProgress) ? 0 : -1
        }

        static let pushTransferProgress: git_push_transfer_progress = {
            (current, total, bytes, payload) in
            guard let callbacks = RemoteCallbacks.fromPayload(payload)
            else { return -1 }
            let progress = PushTransferProgress(current: current, total: total,
                                                bytes: bytes)

            return callbacks.pointee.uploadProgress!(progress) ? 0 : -1
        }

        static let sidebandMessage: git_transport_message_cb = {
            (cString, length, payload) in
            guard let callbacks = RemoteCallbacks.fromPayload(payload)
            else { return -1 }
            guard let cString = cString
            else { return 0 }
            let stringData = Data(bytes: cString, count: Int(length))
            guard let message = String(data: stringData, encoding: .utf8)
            else { return 0 }

            return callbacks.pointee.sidebandMessage!(message) ? 0 : -1
        }
    }

    /// Calls the given action with a populated callbacks struct.
    /// The "with" pattern is needed because of the need to make a mutable copy
    /// of the given callbacks as a payload, and perform the action within the
    /// scope of that copy.
    static func withCallbacks<T>(
        _ callbacks: RemoteCallbacks,
        action: (git_remote_callbacks) throws -> T
    ) rethrows -> T {
        var gitCallbacks = git_remote_callbacks.defaultOptions()
        var mutableCallbacks = callbacks

        return try withUnsafeMutableBytes(of: &mutableCallbacks) {
            (buffer) in
            gitCallbacks.payload = buffer.baseAddress

            gitCallbacks.credentials = Callbacks.credentials
            if callbacks.downloadProgress != nil {
                gitCallbacks.transfer_progress = Callbacks.transferProgress
            }
            if callbacks.uploadProgress != nil {
                gitCallbacks.push_transfer_progress = Callbacks.pushTransferProgress
            }
            return try action(gitCallbacks)
        }
    }
}

extension Array where Element == String {
    /// Converts the given array to a `git_strarray` and calls the given block.
    /// This is patterned after `withArrayOfCStrings` except that function does
    /// not produce the necessary type.
    /// - parameter block: The block called with the resulting `git_strarray`. To
    /// use this array outside the block, use `git_strarray_copy()`.
    func withGitStringArray<T>(block: (git_strarray) throws -> T) rethrows -> T {
        let lengths = map { $0.utf8.count + 1 }
        let offsets = [0] + scan(lengths, 0, +)
        var buffer = [Int8]()

        buffer.reserveCapacity(offsets.last!)
        for string in self {
            buffer.append(contentsOf: string.utf8.map { Int8($0) })
            buffer.append(0)
        }

        let bufferSize = buffer.count

        return try buffer.withUnsafeMutableBufferPointer { pointer -> T in
            let boundPointer = UnsafeMutableRawPointer(pointer.baseAddress!)
                .bindMemory(to: Int8.self, capacity: bufferSize)
            var cStrings: [UnsafeMutablePointer<Int8>?] =
            offsets.map { boundPointer + $0 }

            cStrings[cStrings.count-1] = nil
            return try cStrings.withUnsafeMutableBufferPointer { arrayBuffer -> T in
                let strarray = git_strarray(strings: arrayBuffer.baseAddress, count: count)
                return try block(strarray)
            }
        }
    }
}

extension git_strarray: RandomAccessCollection {
    public var startIndex: Int { 0 }
    public var endIndex: Int { count }

    public subscript(index: Int) -> String? {
        return self.strings[index].map { String(cString: $0) }
    }
}

func scan<S: Sequence, U>(
    _ seq: S,
    _ initial: U,
    _ combine: (U, S.Iterator.Element) -> U) -> [U] {
    var result: [U] = []
    var runningResult = initial

    result.reserveCapacity(seq.underestimatedCount)
    for element in seq {
        runningResult = combine(runningResult, element)
        result.append(runningResult)
    }
    return result
}

extension git_credential_t: OptionSet {}
