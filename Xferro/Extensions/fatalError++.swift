//
//  fatalError++.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

public enum FatalErrorReason: String, Hashable {
    case abstract
    case deprecated
    case illegal
    case invalid
    case impossible
    case unavailable
    case unexpected
    case unimplemented
    case unknown
    case unsupported
}

func fatalError(
    _ reason: FatalErrorReason,
    file: StaticString = #file,
    function: StaticString = #function,
    line: UInt = #line
) -> Never {
    switch reason {
    case .abstract:
        fatalError("abstract method called", file: file, line: line)
    case .illegal:
        fatalError("illegal", file: file, line: line)
    case .impossible:
        fatalError("It's but impossible", file: file, line: line)
    case .unavailable:
        fatalError("\(function) unavailable", file: file, line: line)
    case .unimplemented:
        fatalError("\(function) unimplemented", file: file, line: line)
    case .unsupported:
        fatalError("\(function) unsupported", file: file, line: line)
    default:
        fatalError()
    }
}
