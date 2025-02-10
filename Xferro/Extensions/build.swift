//
//  build.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

@_transparent
func withMutableScope<V>(
    _ initialValue: consuming V,
    modify: (inout V) throws -> ()
) rethrows -> V {
    var value = consume initialValue

    try modify(&value)

    return value
}

@inlinable
public func build<T>(
    _ x: consuming T,
    with f: ((inout T) throws -> ())
) rethrows -> T {
    var _x = x

    try f(&_x)

    return _x
}
