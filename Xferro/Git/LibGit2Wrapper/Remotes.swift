//
//  Remotes.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

/// A remote in a git repository.
public struct Remote: Hashable {
    public enum Direction: Int32 {
        case Fetch = 0 // GIT_DIRECTION_FETCH
        case Push  = 1 //GIT_DIRECTION_PUSH
    }

    /// The name of the remote.
    public let name: String

    /// The URL of the remote.
    ///
    /// This may be an SSH URL, which isn't representable using `NSURL`.
    public let URL: String?

    public let originURL: String?

    /// The Push URL of the remote.
    ///
    /// This may be an SSH URL, which isn't representable using `NSURL`.
    public let pushURL: String?

    public let originPushURL: String?

    /// Create an instance with a libgit2 `git_remote`.
    public init(_ pointer: OpaquePointer, originURL: String?, originPushURL: String?) {
        name = String(validatingCString: git_remote_name(pointer))!

        let URL: String?
        if let url = git_remote_url(pointer) {
            URL = String(validatingCString: url)
        } else {
            URL = nil
        }
        self.URL = URL

        let pushURL: String?
        if let url = git_remote_pushurl(pointer) {
            pushURL = String(validatingCString: url)
        } else {
            pushURL = nil
        }
        self.pushURL = pushURL

        self.originURL = originURL ?? URL
        self.originPushURL = originPushURL ?? pushURL
    }
}
