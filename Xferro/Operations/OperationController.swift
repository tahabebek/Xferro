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

    func showFailureError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.beginSheetModal(for: AppDelegate.firstWindow)
    }
}
