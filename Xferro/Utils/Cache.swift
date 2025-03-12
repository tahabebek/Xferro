//
//  Cache.swift
//  Xferro
//
//  Created by Taha Bebek on 3/11/25.
//

actor Cache<Value> {
    private var cache: [String: Value] = [:]

    func get(_ key: String) -> Value? {
        return cache[key]
    }

    func set(key: String, value: Value) {
        cache[key] = value
    }

    private func remove(_ key: String) {
        cache.removeValue(forKey: key)
    }

    func clearAll() {
        cache.removeAll()
    }

    func contains(_ key: String) -> Bool {
        return cache.keys.contains(key)
    }

    func count() -> Int {
        return cache.count
    }

    subscript(key: String) -> Value? {
        get {
            return cache[key]
        }
    }
}

typealias LastModifiedDateCache = Cache<Date>
typealias DiffInfoCache = Cache<any DiffInformation>

let lastModifiedCache = LastModifiedDateCache()
let diffInfoCache = DiffInfoCache()
