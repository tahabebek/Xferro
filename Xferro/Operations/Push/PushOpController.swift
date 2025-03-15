import Cocoa
import Combine

enum PushOperationOption {
    case new(Branch)
    case currentBranch
    case named(String)
}

typealias ProgressValue = (current: Float, total: Float)

final class PushOpController: PasswordOpController {
    let remoteOption: PushOperationOption
    var progressSubject = PassthroughSubject<ProgressValue, Never>()

    init(remoteOption: PushOperationOption, repository: Repository) {
        self.remoteOption = remoteOption
        super.init(repository: repository)
    }

    required init(repository: Repository) {
        fatalError(.unimplemented)
    }

    nonisolated
    func progressCallback(progress: PushTransferProgress) -> Bool {
        guard !canceled else { return false }

        Task { @MainActor in
            progressSubject.send((Float(progress.current), Float(progress.total)))
        }
        return true
    }

    override func start() throws {
        let remote: Remote
        let branches: [String]

        switch remoteOption {
        case .new(let branch):
            try pushNewBranch(repository, branch)
            return
        case .currentBranch:
            let head = Head.of(repository)
            guard case .branch(let currentBranch, _) = head else {
                throw RepoError.detachedHead
            }
            guard let trackingBranch = repository.trackingBranch(of: currentBranch),
                  let trackedRemote = Remote(name: trackingBranch.name, repository: repository.pointer) else {
                try pushNewBranch(repository, currentBranch)
                return
            }
            remote = trackedRemote
            branches = [currentBranch.name]
        case .named(let remoteName):
            guard let namedRemote = repository.remote(named: remoteName) else {
                fatalError(.invalid)
            }
            let localTrackingBranches = repository.localBranches().mustSucceed(repository.gitDir).filter {
                repository.trackingBranch(of: $0)?.remoteName == remoteName
            }
            guard !localTrackingBranches.isEmpty else {
                let alert = NSAlert()
                alert.messageString = .noRemoteBranches(remoteName)
                alert.beginSheetModal(for: NSApplication.shared.windows.first!)
                return
            }

            remote = namedRemote
            branches = localTrackingBranches.map { $0.name }
        }

        let alert = NSAlert()
        let remoteName = remote.name ?? "origin"
        let message: UIString = branches.count == 1 ?
            .confirmPush(localBranch: branches.first!,
                         remote: remoteName) :
            .confirmPushAll(remote: remoteName)

        alert.messageString = message
        alert.addButton(withString: .push)
        alert.addButton(withString: .cancel)

        alert.beginSheetModal(for: NSApplication.shared.windows.first!) { [weak self] response in
            guard let self else { return }
            if response == .alertFirstButtonReturn {
                push(repository, branches: branches, remote: remote)
            }
            else {
                ended(result: .canceled)
            }
        }
    }

    func pushNewBranch(_ repository: Repository, _ branch: Branch) throws {
        let sheetController = PushNewPanelController.controller()

        var trackingBranchName = repository.trackingBranchName(of: branch)
        sheetController.alreadyTracking = trackingBranchName != nil
        sheetController.setRemotes(repository.remoteNames())

        NSApplication.shared.windows.first?.beginSheet(sheetController.window!) { response in
            guard response == .OK else {
                self.ended(result: .canceled)
                return
            }
            guard let remote = repository.remote(named: sheetController.selectedRemote) else {
                self.ended(result: .failure)
                return
            }

            self.push(repository, branches: [branch.name], remote: remote, then: {
                // This is now on the repo queue
                if let remoteName = remote.name {
                    DispatchQueue.main.async {
                        if sheetController.setTrackingBranch {
                            trackingBranchName =
                            remoteName +/
                            branch.name
                        }
                    }
                }
            })
        }
    }

    override func shoudReport(error: NSError) -> Bool {
        return true
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
        then callback: (@Sendable () -> Void)? = nil
    ) {
        tryRepoOperation { [weak self] in
            guard let self else { return }
            let callbacks = RemoteCallbacks(
                passwordBlock: getPassword,
                downloadProgress: nil,
                uploadProgress: progressCallback
            )
            
            try repository.push(branches: branches, remote: remote, callbacks: callbacks)
            callback?()
            refsChangedAndEnded()
        }
    }
}
