//
//  Pointer++.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation

protocol CallbackInitializable
{
    /// Initializes an instance with a callback that may instead return
    /// an error code.
    /// - parameter callback: Either initializes the given pointer or returns
    /// a libgit2 error code.
    static func from(_ callback: (inout Self?) -> Int32) throws -> Self
}

extension CallbackInitializable
{
    static func from(_ callback: (inout Self?) -> Int32) throws -> Self
    {
        var pointer: Self?
        let result = callback(&pointer)
        guard result >= 0,
              let finalPointer = pointer
        else {
            throw NSError(gitError: result, pointOfFailure: "from callback")
        }

        return finalPointer
    }
}

extension UnsafePointer: CallbackInitializable {}
extension UnsafeMutablePointer: CallbackInitializable {}
extension OpaquePointer: CallbackInitializable {}
