//
//  Collection++.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

import Foundation

extension Collection {
    var bounds: Range<Index> {
        startIndex..<endIndex
    }

    var lastIndex: Index? {
        guard !isEmpty else {
            return nil
        }

        return self.index(atDistance: self.count - 1)
    }

    var second: Element? {
        guard count > 1 else {
            return nil
        }

        return self[index(self.startIndex, offsetBy: 1)]
    }

    var last: Element? {
        guard let lastIndex else {
            return nil
        }

        return self[lastIndex]
    }

    func containsIndex(_ index: Index) -> Bool {
        index >= startIndex && index < endIndex
    }

    func contains(after index: Index) -> Bool {
        containsIndex(index) && containsIndex(self.index(after: index))
    }

    func contains(_ bounds: Range<Index>) -> Bool {
        containsIndex(bounds.lowerBound) && containsIndex(index(bounds.upperBound, offsetBy: -1))
    }

    func index(atDistance distance: Int) -> Index {
        index(startIndex, offsetBy: distance)
    }

    func index(_ index: Index, insetBy distance: Int) -> Index {
        self.index(index, offsetBy: -distance)
    }

    func index(_ index: Index, offsetByDistanceFromStartIndexFor otherIndex: Index) -> Index {
        self.index(index, offsetBy: distanceFromStartIndex(to: otherIndex))
    }

    func indices(of element: Element) -> [Index] where Element: Equatable {
        indices.filter({ self[$0] == element })
    }

    func index(before index: Index) -> Index where Index: Strideable {
        index.predecessor()
    }

    func index(after index: Index) -> Index where Index: Strideable {
        index.successor()
    }

    func distanceFromStartIndex(to index: Index) -> Int {
        distance(from: startIndex, to: index)
    }

    func _stride() -> Index.Stride where Index: Strideable {
        startIndex.distance(to: endIndex)
    }

    func range(from range: Range<Int>) -> Range<Index> {
        index(atDistance: range.lowerBound)..<index(atDistance: range.upperBound)
    }

    func indexes(where condition: (Element) throws -> Bool) rethrows -> [Int] {
        var indices: [Int] = []
        for (index, value) in enumerated() {
            if try condition(value) { indices.append(index) }
        }
        return indices
    }
}
