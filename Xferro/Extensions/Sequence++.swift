//
//  Sequence++.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

extension Sequence {
    @inlinable
    public func zip<S: Sequence>(_ other: S) -> Zip2Sequence<Self, S> {
        return Swift.zip(self, other)
    }
}
