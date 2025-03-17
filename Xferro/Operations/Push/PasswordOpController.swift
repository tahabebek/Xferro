import Cocoa
import Combine

/// An operation that may require a password.
class PasswordOpController: OperationController {
    let urlInfo: Box<(host: String, path: String, port: Int)> = .init(("", "", 80))
    private(set) var passwordController: PasswordPanelController?
    private var closeObserver: NSObjectProtocol?
    private var closeSink: AnyCancellable?

    required override init(repository: Repository) {
        super.init(repository: repository)
        let nc = NotificationCenter.default
        closeSink = nc.publisher(
            for: NSWindow.willCloseNotification,
            object: AppDelegate.firstWindow
        )
        .sinkOnMainQueue { [weak self] _ in
            self?.abort()
        }
    }

    override func abort() {
        passwordController = nil
    }

    /// User/password callback
    nonisolated func getPassword() -> (String, String)? {
        guard !Thread.isMainThread else {
            assertionFailure("password callback on main thread")
            return nil
        }
        guard DispatchQueue.main.sync(execute: {
            MainActor.assumeIsolated { passwordController == nil }
        })
        else {
            assertionFailure("already have a password sheet")
            return nil
        }
        let (window, controller) = DispatchQueue.main.sync {
            MainActor.assumeIsolated {
                let controller = PasswordPanelController()
                self.passwordController = controller
                return (AppDelegate.firstWindow, controller)
            }
        }
        guard let urlInfo = self.urlInfo.value else { return nil }

        return controller.getPassword(
            parentWindow: window,
            host: urlInfo.host,
            path: urlInfo.path,
            port: UInt16(urlInfo.port)
        )
    }

    func setKeychainInfo(from url: URL) {
        urlInfo.value = (url.host ?? "", url.path, url.port ?? url.defaultPort)
    }
}
