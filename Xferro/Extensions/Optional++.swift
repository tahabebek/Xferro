//
//  Optional++.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

infix operator ??=: AssignmentPrecedence
infix operator =??: AssignmentPrecedence

@_transparent
 func _flattenOptional<T>(_ x: T??) -> T? {
    x ?? nil
}

extension Optional {
    @inlinable
     func map(into wrapped: inout Wrapped) {
        map { wrapped = $0 }
    }

    @inlinable
     mutating func mutate<T>(_ transform: ((inout Wrapped) throws -> T)) rethrows -> T? {
        guard self != nil else {
            return nil
        }

        return try transform(&self!)
    }

    @inlinable
     mutating func remove() -> Wrapped {
        defer {
            self = nil
        }

        return self!
    }
}

extension Optional {
     static func ??= (lhs: inout Optional<Wrapped>, rhs: @autoclosure () -> Wrapped) {
        if lhs == nil {
            lhs = rhs()
        }
    }

     static func ??= (lhs: inout Optional<Wrapped>, rhs: @autoclosure () -> Wrapped?) {
        if lhs == nil, let rhs = rhs() {
            lhs = rhs
        }
    }

     static func =?? (lhs: inout Wrapped, rhs: Self) {
        if let rhs = rhs {
            lhs = rhs
        }
    }

     static func =?? (lhs: inout Self, rhs: Self?) {
        if let rhs = rhs.compact() {
            lhs = rhs
        }
    }
}

extension Optional {
     func compact<T>() -> T? where Wrapped == T? {
        return self ?? .none
    }

     func compact<T>() -> T? where Wrapped == T?? {
        return (self ?? .none) ?? .none
    }

     func compact<T>() -> T? where Wrapped == T??? {
        return ((self ?? .none) ?? .none) ?? .none
    }
}

public extension Optional {
    /// An error encountered while unwrapping an `Optional`.
     enum UnwrappingError: CustomDebugStringConvertible, Error {
        case unexpectedlyFoundNil(at: SourceCodeLocation)

        public static var unexpectedlyFoundNil: Self {
            .unexpectedlyFoundNil(at: .unavailable)
        }

        public var debugDescription: String {
            switch self {
            case .unexpectedlyFoundNil(let location):
                if location == .unavailable {
                    return "Unexpectedly found nil while unwrapping an \(String(describing: Optional<Wrapped>.self))."
                } else {
                    return "Unexpectedly found nil while unwrapping an \(String(describing: Optional<Wrapped>.self)) value at \(location)."
                }
            }
        }
    }

    @_transparent
    @inlinable
     func unwrapOrThrow(
        _ error: @autoclosure () throws -> Error
    ) throws -> Wrapped {
        if let wrapped = self {
            return wrapped
        } else {
            throw try error()
        }
    }
}

#if DEBUG
extension Optional {
    /// Unwraps this `Optional`.
    ///
    /// - Throws: `UnwrappingError` if the instance is `nil`.
    /// - Returns: The unwrapped value of this instance.
    @inlinable
     func unwrap(
        file: StaticString = #file,
        fileID: StaticString = #fileID,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt = #column
    ) throws -> Wrapped {
        guard let wrapped = self else {
            throw UnwrappingError.unexpectedlyFoundNil(
                at: SourceCodeLocation(
                    file: file,
                    fileID: fileID,
                    function: function,
                    line: line,
                    column: column
                )
            )
        }

        return wrapped
    }
}
#else
extension Optional {
    /// Unwraps this `Optional`.
    ///
    /// - Throws: `UnwrappingError` if the instance is `nil`.
    /// - Returns: The unwrapped value of this instance.
    @inlinable
     func unwrap() throws -> Wrapped {
        guard let wrapped = self else {
            throw UnwrappingError.unexpectedlyFoundNil(at: .unavailable)
        }

        return wrapped
    }
}
#endif

extension Optional {
    @_transparent
    @discardableResult
    @inlinable
     mutating func unwrapOrInitializeInPlace(
        default fallback: () throws -> Wrapped
    ) rethrows -> Wrapped {
        if let wrapped = self {
            return wrapped
        } else {
            let value = try fallback()

            self = .some(value)

            return value
        }
    }

    @_transparent
    @discardableResult
    @inlinable
     mutating func unwrapOrInitializeInPlace(
        default fallback: () async throws -> Wrapped
    ) async rethrows -> Wrapped {
        if let wrapped = self {
            return wrapped
        } else {
            let value = try await fallback()

            self = .some(value)

            return value
        }
    }

    @_transparent
    @discardableResult
    @inlinable
     mutating func unwrapOrInitializeInPlace(
        default fallback: () throws -> Wrapped?
    ) throws -> Wrapped {
        if let wrapped = self {
            return wrapped
        } else {
            let value = try fallback().unwrap()

            self = .some(value)

            return value
        }
    }

    @_transparent
    @discardableResult
    @inlinable
     mutating func unwrapOrInitializeInPlace(
        default fallback: () async throws -> Wrapped?
    ) async throws -> Wrapped {
        if let wrapped = self {
            return wrapped
        } else {
            let value = try await fallback().unwrap()

            self = .some(value)

            return value
        }
    }

    @_transparent
    @discardableResult
    @inlinable
     mutating func unwrapWithMutableScope<Result>(
        _ operation: (inout Wrapped) throws -> Result
    ) throws -> Result {
        var unwrapped = try unwrap()

        let result = try operation(&unwrapped)

        self = unwrapped

        return result
    }
}

#if DEBUG
extension Optional {
    /// Force unwraps this `Optional`.
    @_transparent
    @inlinable
    @_disfavoredOverload
     func forceUnwrap(
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line,
        column: UInt = #column
    ) throws -> Wrapped {
        try! unwrap(file: file, line: line)
    }
}
#else
extension Optional {
    /// Force unwraps this `Optional`.
    @inlinable
     func forceUnwrap() throws -> Wrapped {
        try! unwrap()
    }
}
#endif

extension Optional {
     var _selfAssumingNonNil: Self {
        if self == nil {
            assertionFailure()
        }

        return self
    }
}

extension Optional where Wrapped: Collection {
     var isNilOrEmpty: Bool {
        map({ $0.isEmpty }) ?? true
    }
}
