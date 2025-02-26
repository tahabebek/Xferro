//
//  Repository+Ignore.swift
//  Xferro
//
//  Created by Taha Bebek on 2/20/25.
//

import Foundation

extension Repository {
    func ignore(_ pattern: String) {
        lock.lock()
        defer { lock.unlock() }
        let ignoreURL = workDir.appendingPathComponent(".gitignore")
        let currentIgnoreContent: String
        do {
            currentIgnoreContent = try String(contentsOf: ignoreURL, encoding: .utf8)
        } catch {
            currentIgnoreContent = ""
        }

        var updatedIgnoreContent = currentIgnoreContent
        if !updatedIgnoreContent.contains(pattern) {
            if !currentIgnoreContent.isEmpty {
                updatedIgnoreContent += "\n"
            }
            updatedIgnoreContent += pattern
        } else {
            fatalError("Pattern '\(pattern)' already exists in .gitignore")
        }

        do {
            try updatedIgnoreContent.write(to: ignoreURL, atomically: true, encoding: .utf8)
        } catch {
            fatalError(.unexpected)
        }
    }

    func unignore(_ pattern: String) {
        lock.lock()
        defer { lock.unlock() }
        let ignoreURL = workDir.appendingPathComponent(".gitignore")
        if !FileManager.fileExists(at: ignoreURL.path) {
            try! "".write(to: ignoreURL, atomically: true, encoding: .utf8)
        }
        let content = try! String(contentsOfFile: ignoreURL.path, encoding: .utf8)
        let lines = content.lines
        let filteredLines = lines.filter { $0 != pattern }

        // If nothing changed, pattern wasn't found
        if filteredLines.count == lines.count {
            fatalError("Pattern '\(pattern)' not found in .gitignore")
        }

        let newContent = filteredLines.joined(separator: "\n")
        do {
            try newContent.write(toFile: ignoreURL.path, atomically: true, encoding: .utf8)
        } catch {
            fatalError(.unexpected)
        }
    }

    func ignores(absolutePath: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard absolutePath.hasPrefix(workDir.path) else {
            fatalError(.invalid)
        }
        let relativePathSubstring = absolutePath.dropFirst(workDir.path.count)
        let relativePath = relativePathSubstring.hasPrefix("/") ? String(relativePathSubstring.dropFirst()) : String(relativePathSubstring)
        return ignores(relativePath: relativePath)
    }
    
    func ignores(relativePath: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        var ignored: Int32 = 0

        guard git_ignore_path_is_ignored(&ignored, self.pointer, relativePath) == 0 else {
            fatalError(GitError.getLastErrorMessage())
        }
        return ignored > 0
    }

    func gitignoreLines() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        let ignoreURL = workDir.appendingPathComponent(".gitignore")

        guard FileManager.fileExists(at: ignoreURL.path) else {
            return []
        }
        let content = try! String(contentsOfFile: ignoreURL.path, encoding: .utf8)
        return content.lines
            .filter {
                !$0.hasPrefix("#")
            }
            .filter {
                !$0.isEmptyOrWhitespace
            }
    }
}
