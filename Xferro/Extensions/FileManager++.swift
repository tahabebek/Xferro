//
//  FileManager++.swift
//  Xferro
//
//  Created by Taha Bebek on 2/26/25.
//

import Foundation

extension FileManager {
    static func fileExists(at path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }

    static func fileExists(at path: String, isDirectory: UnsafeMutablePointer<ObjCBool>?) -> Bool {
        FileManager.default.fileExists(atPath: path, isDirectory: isDirectory)
    }

    static var homeDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
    }

    static func contentsOfDirectory(_ url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions = []) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: mask)
    }

    static func attributesOfItem(at path: String) throws -> [FileAttributeKey : Any] {
        try FileManager.default.attributesOfItem(atPath: path)
    }

    static func removeItem(at path: String) throws {
        try FileManager.default.removeItem(atPath: path)
    }

    static func createDirectory(at path: String, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }

    static func createDirectory(atURL url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey : Any]? = nil) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: createIntermediates, attributes: attributes)
    }


    static func createFile(at path: String, contents data: Data?, attributes attr: [FileAttributeKey : Any]? = nil) -> Bool {
        FileManager.default.createFile(atPath: path, contents: data, attributes: attr)
    }

    static func removeItem(atURL: URL) throws {
        try FileManager.default.removeItem(at: atURL)
    }

    static var tempDirectory: URL {
        FileManager.default.temporaryDirectory
    }

    static func urls(forDirectory directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        FileManager.default.urls(for: directory, in: domainMask)
    }
}
