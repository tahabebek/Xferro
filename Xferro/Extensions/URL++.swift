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

    func pathByCollapsingTilde() -> String {
        let homeDirectory = FileManager.homeDirectory.path
        if path.hasPrefix(homeDirectory) {
            let shortPath = "~" + path.dropFirst(homeDirectory.count)
            return shortPath
        }
        return path
    }

    func subfolders() throws -> [URL] {
        let contents = try FileManager.contentsOfDirectory(self, includingPropertiesForKeys: [.isDirectoryKey], options: [])
        return try contents.filter { try $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory ?? false }
    }

    func modificationDate() throws -> Date {
        let attributes = try FileManager.attributesOfItem(at: path)
        return attributes[FileAttributeKey.modificationDate] as! Date
    }
}

extension URL
{
    static func +/ (left: URL, right: String) -> URL
    {
        return left.appendingPathComponent(right)
    }
}
