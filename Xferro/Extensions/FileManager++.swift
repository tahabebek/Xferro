//
//  FileManager++.swift
//  Xferro
//
//  Created by Taha Bebek on 2/26/25.
//

import Foundation

extension FileManager {
    static func fileExists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    static func fileExists(_ path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        FileManager.default.fileExists(atPath: path, isDirectory: isDirectory)
    }

    static var homeDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    static func contentsOfDirectory(_ url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions = []) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: mask)
    }

    static func attributesOfItem(_ path: String) throws -> [FileAttributeKey : Any] {
        try FileManager.default.attributesOfItem(atPath: path)
    }

    static func removeItem(_ path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }

    static func moveItem(_ srcURL: URL, to dstURL: URL) throws {
        try FileManager.default.moveItem(at: srcURL, to: dstURL)
    }
    static func createDirectory(_ path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }

    static func createDirectory(_ url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }

    @discardableResult
    static func createFile(_ path: String, contents data: Data?, attributes attr: [FileAttributeKey : Any]? = nil) -> Bool {
        FileManager.default.createFile(atPath: path, contents: data, attributes: attr)
    }

    static func removeItem(_ url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }

    static var tempDirectory: URL {
        FileManager.default.temporaryDirectory
    }

    static func urls(in directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        FileManager.default.urls(for: directory, in: domainMask)
    }

    static func lastModificationDate(of filePath: String) -> Date? {
        let fileManager = FileManager.default

        do {
            let attributes = try fileManager.attributesOfItem(atPath: filePath)
            if let modificationDate = attributes[.modificationDate] as? Date {
                return modificationDate
            }
            return nil
        } catch {
            print("Error getting file attributes: \(error)")
            return nil
        }
    }
}
