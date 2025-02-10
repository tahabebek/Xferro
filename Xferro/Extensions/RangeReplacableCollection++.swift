//
//  RangeReplacableCollection++.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

extension RangeReplaceableCollection {
    @inlinable
    public init(capacity: Int) {
        self.init()

        reserveCapacity(capacity)
    }
}

extension RangeReplaceableCollection {
    public func appending<S: Sequence>(
        contentsOf other: S
    ) -> Self where S.Element == Element {
        build(self) {
            $0.append(contentsOf: other)
        }
    }
}

extension RangeReplaceableCollection where Self: BidirectionalCollection & MutableCollection  {
    public var mutableFirst: Element? {
        get {
            first
        } set {
            if let newValue {
                self[startIndex] = newValue
            } else {
                self.removeFirst()
            }
        }
    }

    public var mutableLast: Element? {
        get {
            last
        } set {
            if let newValue {
                if let lastIndex = lastIndex {
                    self[lastIndex] = newValue
                } else {
                    self.append(newValue)
                }
            } else {
                _ = popLast()
            }
        }
    }

    public mutating func mutateFirstAndLast(
        first mutateFirst: (inout Element?) throws -> Void,
        last mutateLast: (inout Element?) throws -> Void
    ) rethrows {
        let originalCount = count

        try mutateFirst(&mutableFirst)

        if originalCount > 1 {
            try mutateLast(&mutableLast)
        }
    }

    public mutating func append(
        contentsOf newElements: some Sequence<Element>,
        join: (Element, Element) -> Element?
    ) {
        for element in newElements {
            if let last, let joined = join(last, element) {
                self.mutableLast = joined
            } else {
                self.append(element)
            }
        }
    }

    public mutating func append(
        contentsOf newElements: some Collection<Element>,
        join: (Element, Element) -> Element?
    ) {
        for element in newElements {
            if let last, let joined = join(last, element) {
                self.mutableLast = joined
            } else {
                self.append(element)
            }
        }
    }
}

extension RangeReplaceableCollection {
    @discardableResult
    public mutating func replace(
        at index: Index,
        with replacement: Element
    ) -> Element {
        insert(replacement, at: index)

        return remove(at: self.index(index, offsetBy: 1))
    }

    @discardableResult
    public mutating func replace<S: Collection>(
        at index: Index,
        with replacements: S
    ) -> Element where S.Element == Element {
        let oldCount = count

        self.insert(contentsOf: replacements, at: index)

        return self.remove(at: self.index(index, offsetBy: (count - oldCount)))
    }

    @discardableResult
    public mutating func replace<S: Sequence>(
        at indices: S,
        with replacement: Element
    ) -> [Element] where S.Element == Index {
        return indices.map({ self.insert(replacement, at: $0); return self.remove(at: self.index($0, offsetBy: 1)) })
    }
}

extension RangeReplaceableCollection {
    @discardableResult
    public mutating func replace(
        _ predicate: ((Element) -> Bool),
        with replacement: Element
    ) -> [Element] {
        return replace(at: indices.filter({ predicate(self[$0]) }), with: replacement)
    }
}

extension MutableCollection where Self: RangeReplaceableCollection {
    public mutating func remove<C: Collection>(
        elementsAtIndices indicesToRemove: C
    ) where C.Element == Index {
        guard !indicesToRemove.isEmpty else {
            return
        }

        // Check if the indices are sorted.
        var isSorted = true
        var prevIndex = indicesToRemove.first!
        let secondIndex = indicesToRemove.index(after: indicesToRemove.startIndex)
        for index in indicesToRemove[secondIndex...] {
            if index < prevIndex {
                isSorted = false
                break
            }
            prevIndex = index
        }

        if isSorted {
            remove(elementsAtSortedIndices: indicesToRemove)
        } else {
            remove(elementsAtSortedIndices: indicesToRemove.sorted())
        }
    }

    public func removing<C: Collection>(
        elementsAtIndices indicesToRemove: C
    ) -> Self where C.Element == Index {
        build(self) {
            $0.remove(elementsAtIndices: indicesToRemove)
        }
    }

    private mutating func remove<C: Collection>(
        elementsAtSortedIndices indicesToRemove: C
    ) where C.Element == Index {
        // Shift the elements we want to keep to the left.
        var destIndex = indicesToRemove.first!
        precondition(indices.contains(destIndex), "Index out of range")

        var srcIndex = index(after: destIndex)
        let previousRemovalIndex = destIndex
        func shiftLeft(untilIndex index: Index) {
            precondition(index != previousRemovalIndex, "Duplicate indices")
            while srcIndex < index {
                swapAt(destIndex, srcIndex)
                formIndex(after: &destIndex)
                formIndex(after: &srcIndex)
            }
            formIndex(after: &srcIndex)
        }
        let secondIndex = indicesToRemove.index(after: indicesToRemove.startIndex)
        for removeIndex in indicesToRemove[secondIndex...] {
            precondition(indices.contains(removeIndex), "Index out of range")
            shiftLeft(untilIndex: removeIndex)
        }
        shiftLeft(untilIndex: endIndex)

        // Remove the extra elements from the end of the collection.
        removeSubrange(destIndex..<endIndex)
    }
}

extension RangeReplaceableCollection {
    @inlinable
    public mutating func removeAfter(predicate: (Element) throws -> Bool) rethrows {
        if let index = try self.firstIndex(where: predicate) {
            self.removeSubrange(index...)
        }
    }

    @inlinable
    public mutating func removeFrom(predicate: (Element) throws -> Bool) rethrows {
        if let index = try self.firstIndex(where: predicate) {
            self.removeSubrange(index..<self.endIndex)
        }
    }
}

extension RangeReplaceableCollection where Element: Equatable {
    @discardableResult
    public mutating func replace(allOf element: Element, with replacement: Element) -> [Element] {
        return replace(at: indices.filter({ self[$0] == element }), with: replacement)
    }
}

extension RangeReplaceableCollection where Self: BidirectionalCollection & MutableCollection {
    public func reduce<T>(
        byUnwrapping transform: (Element) -> T?,
        _ combine: (T, T) -> Element
    ) -> Self {
        reduce(into: Self(capacity: underestimatedCount)) { result, element in
            if let last = result.last, let lhs = transform(last), let rhs = transform(element) {
                result.mutableLast = combine(lhs, rhs)
            } else {
                result.append(element)
            }
        }
    }
}
