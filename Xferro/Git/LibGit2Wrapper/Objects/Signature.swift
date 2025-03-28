//
//  Signature.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import Foundation

struct Signature: Codable {
    let name: String
    let email: String
    let time: Date
    let timeZone: TimeZone

    init(name: String, email: String, time: Date = Date(), timeZone: TimeZone = TimeZone.autoupdatingCurrent) {
        self.name = name
        self.email = email
        self.time = time
        self.timeZone = timeZone
    }

    init(_ signature: git_signature) {
        name = String(validatingCString: signature.name)!
        email = String(validatingCString: signature.email)!
        time = Date(timeIntervalSince1970: TimeInterval(signature.when.time))
        timeZone = TimeZone(secondsFromGMT: 60 * Int(signature.when.offset))!
    }

    func makeUnsafeSignature() -> Result<UnsafeMutablePointer<git_signature>, NSError> {
        var signature: UnsafeMutablePointer<git_signature>? = nil
        let time = git_time_t(self.time.timeIntervalSince1970)    // Unix epoch time
        let offset = Int32(timeZone.secondsFromGMT(for: self.time) / 60)
        let signatureResult = git_signature_new(&signature, name, email, time, offset)
        guard signatureResult == GIT_OK.rawValue, let signatureUnwrap = signature else {
            let err = NSError(gitError: signatureResult, pointOfFailure: "git_signature_new")
            return .failure(err)
        }
        return .success(signatureUnwrap)
    }

    static func `default`(_ repository: Repository, staticLock: NSRecursiveLock? = nil) -> Result<Signature, NSError> {
        if let staticLock {
            staticLock.lock()
        } else {
            repository.lock.lock()
        }
        defer {
            if let staticLock {
                staticLock.unlock()
            } else {
                repository.lock.unlock()
            }
        }
        var signature: UnsafeMutablePointer<git_signature>? = nil
        let signatureResult = git_signature_default(&signature, repository.pointer)
        if signatureResult == GIT_OK.rawValue, let signatureUnwrap = signature {
            let s = signatureUnwrap.move()
            return .success(Signature(s))
        }
        guard signatureResult == GIT_ENOTFOUND.rawValue else {
            let err = NSError(gitError: signatureResult, pointOfFailure: "git_signature_default")
            return .failure(err)
        }
        let name = repository.config?.userName ?? NSUserName()
        let email = repository.config?.userEmail ?? "\(NSUserName())@\(ProcessInfo.processInfo.hostName)"
        return .success(Signature(name: name, email: email))
    }
}

extension Signature: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(email)
        hasher.combine(time)
    }
}
