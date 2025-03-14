//
//  Thread++.swift
//  Xferro
//
//  Created by Taha Bebek on 3/14/25.
//

import Foundation

extension Thread {
    /// Performs the block immediately if this is the main thread, or
    /// synchronosly on the main thread otherwise.
    static func syncOnMain<T>(_ block: () throws -> T) rethrows -> T {
        return isMainThread ? try block()
        : try DispatchQueue.main.sync(execute: block)
    }
}
