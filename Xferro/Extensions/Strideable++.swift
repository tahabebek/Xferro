//
//  Strideable++.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

extension Strideable {
    @inlinable
    public mutating func advance(by distance: Stride) {
        self = advanced(by: distance)
    }

    @inlinable
    public mutating func advance() {
        advance(by: 1)
    }
}

extension Strideable {
    @inlinable
    public func successor() -> Self {
        return advanced(by: 1)
    }

    @inlinable
    public func predecessor() -> Self {
        return advanced(by: -1)
    }
}
