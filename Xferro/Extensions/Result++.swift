import Swift

extension Result {
    @discardableResult
    func mustSucceed(_ gitDir: URL) -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            try? FileManager.removeItem(gitDir.appendingPathComponent("index.lock"))
            fatalError(error.localizedDescription)
        }
    }

    var value: Success? {
        guard case .success(let value) = self else {
            return nil
        }
        return value
    }

    func discard() -> Void {
        return ()
    }

    var error: Failure? {
        guard case .failure(let error) = self else {
            return nil
        }
        return error
    }
}
