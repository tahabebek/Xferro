import Swift

extension Result {
    public func mustSucceed() -> Success {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            fatalError(error.localizedDescription)
        }
    }
}
