//
//  FileComparator.swift
//  Xferro
//
//  Created by Taha Bebek on 2/18/25.
//

import Foundation

protocol FileComparator {
    func contentsEqual(_ lhs: URL, _ rhs: URL) -> Bool
}

struct FileManagerComparator: FileComparator {
    func contentsEqual(_ lhs: URL, _ rhs: URL) -> Bool {
        FileManager.default.contentsEqual(atPath: lhs.path, andPath: rhs.path)
    }
}

struct AlwaysFalseComparator: FileComparator {
    func contentsEqual(_ lhs: URL, _ rhs: URL) -> Bool {
        false
    }
}
