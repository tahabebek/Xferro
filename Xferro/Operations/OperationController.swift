import Cocoa

@MainActor
class OperationController {
    nonisolated var canceled: Bool {
        get { canceledMutex.withLock { canceledBox.value } ?? false }
        set { canceledMutex.withLock { canceledBox.value = newValue } }
    }
    private let canceledMutex = NSRecursiveLock()
    private let canceledBox = Box<Bool>(false)

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
