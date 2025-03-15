import Cocoa

@MainActor
class OperationController {
    enum OperationResult
    {
        case success
        case failure
        case canceled
    }

    let repository: Repository
    /// True if the operation is being canceled.
    nonisolated var canceled: Bool {
        get { canceledMutex.withLock { canceledBox.value } ?? false }
        set { canceledMutex.withLock { canceledBox.value = newValue } }
    }
    /// Actions to be executed after the operation succeeds.
    var successActions: [() -> Void] = []

    private let canceledMutex = NSRecursiveLock()
    private let canceledBox = Box<Bool>(false)

    init(repository: Repository) {
        self.repository = repository
    }

    /// Initiates the operation.
    func start() throws {}

    func abort() {}

    func ended(result: OperationResult = .success) {
        if result == .success {
            for action in successActions {
                action()
            }
        }
        successActions.removeAll()
    }

    nonisolated func refsChangedAndEnded() {
        Task { @MainActor in
            self.ended()
        }
    }

    func onSuccess(_ action: @escaping () -> Void) {
        successActions.append(action)
    }

    /// Override to suppress errors.
    func shoudReport(error: NSError) -> Bool {
        return true
    }

    func repoErrorMessage(for error: RepoError) -> UIString {
        return error.message
    }

    /// Executes the given block on the repository queue, handling errors and
    /// updating status.
    func tryRepoOperation(block: @escaping (@Sendable () throws -> Void)) {
        repository.queue.executeOffMainThread { [weak self] in
            do {
                try block()
            }
            catch let error {
                guard let self else { return }

                Task { @MainActor in
                    defer {
                        self.ended(result: .failure)
                    }

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
                }
            }
        }
    }

    func showFailureError(_ message: String) {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                let alert = NSAlert()

                alert.messageText = message
                alert.beginSheetModal(for: window)
            }
        }
    }
}
