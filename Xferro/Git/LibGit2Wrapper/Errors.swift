//
//  Errors.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

let libGit2ErrorDomain = "org.libgit2.libgit2"

extension NSError {
    /// Returns an NSError with an error domain and message for libgit2 errors.
    ///
    /// :param: errorCode An error code returned by a libgit2 function.
    /// :param: libGit2PointOfFailure The name of the libgit2 function that produced the
    ///         error code.
    /// :returns: An NSError with a libgit2 error domain, code, and message.
    convenience init(gitError errorCode: Int32, pointOfFailure: String? = nil, description: String? = nil) {
        let code = Int(errorCode)
        var userInfo: [String: String] = [:]
        userInfo[NSLocalizedDescriptionKey] = GitError.getLastErrorMessage() + (description != nil ? " - \(description!)" : "")

        if let pointOfFailure {
            userInfo[NSLocalizedFailureReasonErrorKey] = "\(pointOfFailure) failed."
        }

        self.init(domain: libGit2ErrorDomain, code: code, userInfo: userInfo)
    }
}

public extension Result {
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        default:
            return false
        }
    }
}
