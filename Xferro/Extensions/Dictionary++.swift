//
//  Dictionary++.swift
//  Xferro
//
//  Created by Taha Bebek on 2/16/25.
//

import Foundation

extension Dictionary where Value: SetAlgebra {
    mutating func insert(key: Key, value: Value.Element) {
        if var existing = self[key] {
            existing.insert(value)
            self[key] = existing
        } else {
            self[key] = Value([value])
        }
    }

    mutating func remove(key: Key, value: Value.Element) {
        if var existing = self[key] {
            existing.remove(value)
            self[key] = existing
        }
    }

    func isEmpty(key: Key) -> Bool {
        self[key]?.isEmpty ?? true
    }

    func contains(key: Key, value: Value.Element) -> Bool {
        self[key]?.contains(value) ?? false
    }
}
