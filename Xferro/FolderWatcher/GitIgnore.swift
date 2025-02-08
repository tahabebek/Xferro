//
//  GitIgnore.swift
//  SwiftSpace
//
//  Created by Taha Bebek on 1/6/25.
//

import Foundation

class GitIgnore {
    private var patterns: [String] = []
    private let rootPath: String

    init(rootPath: String) {
        self.rootPath = rootPath
        loadGitIgnore()
    }

    private func loadGitIgnore() {
        let gitignorePath = (rootPath as NSString).appendingPathComponent(".gitignore")
        guard let content = try? String(contentsOfFile: gitignorePath, encoding: .utf8) else {
            print("⚠️ No .gitignore file found or couldn't read it")
            return
        }

        patterns = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }

        print("📋 Loaded \(patterns.count) gitignore patterns")
    }

    func shouldIgnore(path: String) -> Bool {
        // Get relative path from root
        let relativePath = (path as NSString)
            .replacingOccurrences(of: rootPath, with: "")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        for pattern in patterns {
            if matchesGitIgnorePattern(pattern: pattern, path: relativePath) {
                return true
            }
        }
        return false
    }

    private func matchesGitIgnorePattern(pattern: String, path: String) -> Bool {
        var modifiedPattern = pattern

        // Handle basic gitignore pattern rules
        if pattern.hasPrefix("/") {
            modifiedPattern = String(pattern.dropFirst())
        }
        if pattern.hasSuffix("/") {
            modifiedPattern = String(pattern.dropLast())
        }

        // Convert gitignore pattern to regex pattern
        modifiedPattern = modifiedPattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
            .replacingOccurrences(of: "?", with: ".")

        // Handle special cases
        if pattern.hasPrefix("**") {
            modifiedPattern = ".*" + String(modifiedPattern.dropFirst(2))
        }

        do {
            let regex = try NSRegularExpression(pattern: "^" + modifiedPattern + "$")
            let range = NSRange(path.startIndex..<path.endIndex, in: path)
            return regex.firstMatch(in: path, range: range) != nil
        } catch {
            print("❌ Invalid gitignore pattern: \(pattern)")
            return false
        }
    }
}

