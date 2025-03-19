import Cocoa
import Combine

typealias ProgressValue = (current: Float, total: Float)

final class PushOpController: OperationController {
    enum OperationResult {
        case success
        case failure
    }

    let repository: Repository
    let localBranch: Branch
    let remote: Remote
    let force: Bool
    var cancelled = false
    var progressSubject = PassthroughSubject<ProgressValue, Never>()

    init(localBranch: Branch, remote: Remote, repository: Repository, force: Bool = false) {
        self.localBranch = localBranch
        self.remote = remote
        self.force = force
        self.repository = repository
    }

    func progressCallback(progress: PushTransferProgress) -> Bool {
        guard !cancelled else { return false }

        Task { @MainActor in
            progressSubject.send((Float(progress.current), Float(progress.total)))
        }
        return true
    }

    @discardableResult
    func start() async throws -> OperationResult {
        await push(repository, branches: [localBranch.longName], remote: remote, force: force)
    }

    override func repoErrorMessage(for error: RepoError) -> UIString {
        if error.isGitError(GIT_EBAREREPO) {
            return .pushToBare
        }
        else {
            return super.repoErrorMessage(for: error)
        }
    }

    func push(
        _ repository: Repository,
        branches: [String],
        remote: Remote,
        force: Bool
    ) async -> OperationResult {
        let callbacks = RemoteCallbacks(
            passwordBlock: nil,
            downloadProgress: nil,
            uploadProgress: self.progressCallback
        )

        do {
            // Try with libgit2 first
            try repository.push(branches: branches, remote: remote, callbacks: callbacks, force: force)
            return .success
        } catch {
            // If libgit2 fails and it looks like an SSH authentication loop issue,
            // try falling back to CLI git which handles SSH authentication differently
            if let _ = error as? RepoError {
                let remoteName = remote.name ?? "origin"
                let branchSpecs = branches.map { $0.replacingOccurrences(of: "refs/heads/", with: "") }
                
                do {
                    try GitCLI.executeGit(repository, ["push", remoteName] + branchSpecs + (force ? ["--force"] : []))
                } catch {
                    Task { @MainActor in
                        self.showFailureError("Git CLI fallback also failed. Original error: \(error.localizedDescription)")
                        return OperationResult.failure
                    }
                }
            } else {
                Task { @MainActor in
                    switch error {
                    case let repoError as RepoError:
                        self.showFailureError(self.repoErrorMessage(for: repoError).rawValue)

                    case let nsError as NSError where self.shoudReport(error: nsError):
                        var message = error.localizedDescription

                        if let gitError = git_error_last() {
                            let errorString = String(cString: gitError.pointee.message)
                            message.append(" \(errorString)")
                        }
                        self.showFailureError(message)
                    default:
                        break
                    }
                    return OperationResult.failure
                }
            }
        }
        return OperationResult.failure
    }
}
