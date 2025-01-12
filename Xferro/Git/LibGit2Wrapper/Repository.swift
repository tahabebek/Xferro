//
//  Repository.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

final class Repository {
    /// The underlying libgit2 `git_repository` object.
    let pointer: OpaquePointer
    var submodule: Submodule?

    // MARK: - Initializers

    /// Create an instance with a libgit2 `git_repository` object.
    ///
    /// The Repository assumes ownership of the `git_repository` object.
    public init(_ pointer: OpaquePointer, submodule: Submodule? = nil) {
        self.pointer = pointer
        self.submodule = submodule
    }

    // MARK: - Validity/Existence Check

    /// - returns: `.success(true)` iff there is a git repository at `url`,
    ///   `.success(false)` if there isn't,
    ///   and a `.failure` if there's been an error.
    static func isValid(url: URL) -> Result<Bool, NSError> {
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

    static func isGitRepository(url: URL) -> Result<Bool, NSError> {
        var repo: OpaquePointer?
        git_libgit2_init();

        let result = url.withUnsafeFileSystemRepresentation {
            git_repository_open(
                &repo,
                $0
            );
        }


        if (repo != nil) {
            git_repository_free(repo);
        }
        git_libgit2_shutdown();

        switch result {
        case GIT_ENOTFOUND.rawValue:
            return .success(false)
        case GIT_OK.rawValue:
            return .success(true)
        default:
            return .failure(NSError(gitError: result, pointOfFailure: "git_repository_open"))
        }
    }

    class func at(_ url: URL) -> Result<Repository, NSError> {
        var pointer: OpaquePointer? = nil
        let result = url.withUnsafeFileSystemRepresentation {
            git_repository_open(&pointer, $0)
        }

        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_repository_open"))
        }

        let repository = Repository(pointer!)
        return Result.success(repository)
    }

    class func create(at url: URL) -> Result<Repository, NSError> {
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
