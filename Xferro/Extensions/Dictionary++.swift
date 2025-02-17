//
//  Dictionary++.swift
//  Xferro
//
//  Created by Taha Bebek on 2/16/25.
//

import Foundation

extension Dictionary where Key == OID, Value == Set<String> {
    mutating func insert(key: Key, value: String) {
        if var existing = self[key] {
            existing.insert(value)
            self[key] = existing
        } else {
            self[key] = [value]
        }
    }

    mutating func remove(key: Key, value: String) {
        if var existing = self[key] {
            existing.remove(value)
            self[key] = existing
        }
    }

    func isEmpty(key: Key) -> Bool {
        self[key]?.isEmpty ?? true
    }

    func contains(key: Key, value: String) -> Bool {
        self[key]?.contains(value) ?? false
    }


}
