import Foundation

/// Sendable replacement for `git_error`
struct GitError: Sendable {
    let message: String
    let `class`: Int32

    init(_ error: git_error) {
        self.message = error.message.map { String(cString: $0) } ?? ""
        self.class = error.klass
    }

    static func getLastErrorMessage() -> String {
        let error = git_error_last()
        let errorMessage = error?.pointee.message.map { String(cString: $0) } ?? "Git error last is not available"
        return errorMessage
    }
}

enum RepoError: Swift.Error {
    case alreadyWriting
    case authenticationFailed
    case cherryPickInProgress
    case commitNotFound(sha: SHA?)
#warning("add a list of conflicted files")
    case conflict
    case detachedHead
    case duplicateName
    case fileNotFound(path: String)
    case gitError(Int32, GitError?)
    case invalidName(String)
    case invalidNameGiven
    case localConflict
    case mergeInProgress
    case notFound
    case patchMismatch
    case unexpected
    case workspaceDirty

    static func gitError(_ code: Int32) -> Self {
        .gitError(code, Optional<GitError>.none)
    } // nil is ambiguous

    static func gitError(_ code: Int32, _ error: git_error?) -> Self {
        .gitError(code, error.map { GitError($0) })
    }

    var isExpected: Bool {
        switch self {
        case .unexpected: false
        default: true
        }
    }

    var message: UIString {
        switch self {
        case .alreadyWriting:
                .alreadyWriting
        case .authenticationFailed:
                .authenticationFailed
        case .mergeInProgress:
                .mergeInProgress
        case .cherryPickInProgress:
                .cherryPickInProgress
        case .conflict:
                .conflict
        case .duplicateName:
                .duplicateName
        case .localConflict:
                .localConflict
        case .detachedHead:
                .detachedHead
        case .gitError(let code, let error):
            if let error, !error.message.isEmpty {
                .gitErrorMsg(code, error.message)
            }
            else {
                .gitError(code)
            }
        case .invalidName(let name):
                .invalidName(name)
        case .invalidNameGiven:
                .invalidNameGiven
        case .patchMismatch:
                .patchMismatch
        case .commitNotFound(let sha):
                .commitNotFound(sha?.shortString)
        case .fileNotFound(let path):
                .fileNotFound(path)
        case .notFound:
                .notFound
        case .unexpected:
                .unexpected
        case .workspaceDirty:
                .workspaceDirty
        }
    }

    var localizedDescription: String { message.rawValue }
    
    init(gitCode: git_error_code) {
        switch gitCode {
        case GIT_ECONFLICT, GIT_EMERGECONFLICT:
            self = .conflict
        case GIT_EEXISTS:
            self = .duplicateName
        case GIT_ELOCKED:
            self = .alreadyWriting
        case GIT_ENOTFOUND:
            self = .notFound
        case GIT_EUNMERGED:
            self = .mergeInProgress
        case GIT_EUNCOMMITTED, GIT_EINDEXDIRTY:
            self = .workspaceDirty
        case GIT_EINVALIDSPEC:
            self = .invalidNameGiven
        case GIT_EAUTH:
            self = .authenticationFailed
        default:
            self = .gitError(gitCode.rawValue, git_error_last()?.pointee)
        }
    }

    func isGitError(_ code: git_error_code) -> Bool {
        switch self {
        case .gitError(let myCode, _): myCode == code.rawValue
        default: false
        }
    }

    static func throwIfGitError(_ code: Int32) throws {
        guard code == 0 else {
            throw RepoError(gitCode: git_error_code(code))
        }
    }
}

extension RepoError: CustomStringConvertible {
    var description: String { message.rawValue }
}
