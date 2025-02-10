//
//  URL++.swift
//  Xferro
//
//  Created by Taha Bebek on 2/10/25.
//

import Foundation

extension URL {
    var isDirectory: Bool {
        ((try? resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false) || (absoluteString.hasSuffix("/") == true)
    }
}
