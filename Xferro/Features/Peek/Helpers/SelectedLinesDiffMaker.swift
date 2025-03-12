//
//  SelectedLinesDiffMaker.swift
//  Xferro
//
//  Created by Taha Bebek on 3/7/25.
//

import Foundation

enum SelectedLinesDiffMaker {
    enum Result {
        case modified(resultingFileLines: [String], headFileLines: [String])
        case added(resultingFileLines: [String])
        case deleted(resultingFileLines: [String], headFileLines: [String])

        var resultingFileLines: [String] {
            switch self {
            case .modified(resultingFileLines: let lines, headFileLines: _),
                    .added(resultingFileLines: let lines),
                    .deleted(resultingFileLines: let lines, headFileLines: _):
                return lines
            }
        }
    }

    static func makeFileWithSelectedLines(
        repository: Repository,
        filePath: String,
        selectedLines: [DiffLine],
        allHunks: [DiffHunk]
    ) async throws -> Result {
        let headFileResult = GitCLI.showHead(repository, filePath)
        switch headFileResult {
        case .success(let headFileContent):
            let headFileLines = headFileContent.lines
            let path = repository.workDir.appendingPathComponent(filePath).path
            if FileManager.fileExists(path) {
                let currentFileLines = try String(contentsOfFile: path, encoding: .utf8).lines
                let allLinesInHunk = allHunks.flatMap(\.parts).flatMap((\.lines)).filter(\.isAdditionOrDeletion)
                let result = try await makeFileWithSelectedLinesForModifiedFile(
                    repository: repository,
                    headFileLines: headFileLines,
                    currentFileLines: currentFileLines,
                    selectedLines: selectedLines,
                    allLinesInHunk: allLinesInHunk
                )
                return .modified(resultingFileLines: result, headFileLines: headFileLines)
            } else {
                let result = try await makeFileWithSelectedLinesForDeletedFile(
                    repository: repository,
                    headFileLines: headFileLines,
                    selectedLines: selectedLines
                )
                return .deleted(resultingFileLines: result, headFileLines: headFileLines)
            }
        case .failure(let error):
            switch error {
            case .fileNotInHead:
                let path = repository.workDir.appendingPathComponent(filePath).path
                if FileManager.fileExists(path) {
                    let result = try await makeFileWithSelectedLinesForAddedFile(
                        repository: repository,
                        selectedLines: selectedLines
                    )
                    return .added(resultingFileLines: result)
                } else {
                    fatalError(.invalid)
                }
            case .actualError:
                throw error
            }
        }
    }

    static func makeFileWithSelectedLinesInTheHunk(
        repository: Repository,
        filePath: String,
        hunk: DiffHunk,
        allHunks: [DiffHunk]
    ) async throws -> Result {
        let selectedLines = hunk.parts.flatMap(\.lines).filter(\.isSelected)
        return try await makeFileWithSelectedLines(repository: repository, filePath: filePath, selectedLines: selectedLines, allHunks: allHunks)
    }

    static func makeDiff(
        repository: Repository,
        filePath: String,
        hunk: DiffHunk,
        allHunks: [DiffHunk]
    ) async throws -> String {
        let selectedLines = hunk.parts.flatMap(\.lines).filter(\.isSelected)
        return try await makeDiff(repository: repository, filePath: filePath, selectedLines: selectedLines, allHunks: allHunks)
    }

    static func makeDiff(
        repository: Repository,
        filePath: String,
        selectedLines: [DiffLine],
        allHunks: [DiffHunk],
        reverse: Bool = false
    ) async throws -> String {
        let result = try await makeFileWithSelectedLines(
            repository: repository,
            filePath: filePath,
            selectedLines: selectedLines,
            allHunks: allHunks
        )
        switch result {
        case .modified(let resultingFileLines, let headFileLines):
            return try await getDiff(
                repository: repository,
                result: resultingFileLines,
                headFileLines: headFileLines,
                reverse: reverse
            )
        case .added(let resultingFileLines):
            return try await getDiff(
                repository: repository,
                result: resultingFileLines,
                headFileLines: nil,
                reverse: reverse
            )
        case .deleted(let resultingFileLines, let headFileLines):
            return try await getDiff(
                repository: repository,
                result: resultingFileLines,
                headFileLines: headFileLines,
                reverse: reverse
            )
        }
    }

    private static func makeFileWithSelectedLinesForAddedFile(
        repository: Repository,
        selectedLines: [DiffLine]
    ) async throws -> [String] {
        guard selectedLines.isNotEmpty else {
            fatalError(.invalid)
        }
        var result = [String]()
        for selectedLine in selectedLines {
            if case .addition = selectedLine.type {
                result.append(selectedLine.text)
            } else {
                fatalError(.invalid)
            }
        }
        return result
    }

    private static func makeFileWithSelectedLinesForDeletedFile(
        repository: Repository,
        headFileLines: [String],
        selectedLines: [DiffLine]
    ) async throws -> [String] {
        guard selectedLines.isNotEmpty else {
            fatalError(.invalid)
        }
        var result = [String]()
        for headLineIndex in 0..<headFileLines.count  {
            let headLine = headFileLines[headLineIndex]
            var selected = false
            for selectedLine in selectedLines {
                if case .deletion = selectedLine.type {
                    let deletionLineNumber = Int(selectedLine.oldLine)
                    if deletionLineNumber == headLineIndex + 1 {
                        // we found the deleted change, and it is part of selected lines
                        // this line should not be added to the result
                        selected = true
                        break
                    }
                } else {
                    fatalError(.invalid)
                }
            }
            if !selected {
                result.append(headLine)
            }
        }
        return result
    }

    private static func makeFileWithSelectedLinesForModifiedFile(
        repository: Repository,
        headFileLines: [String],
        currentFileLines: [String],
        selectedLines: [DiffLine],
        allLinesInHunk: [DiffLine]
    ) async throws -> [String] {
        guard selectedLines.isNotEmpty else {
            return headFileLines
        }

        var result: [String] = []
        var headLineIndex: Int = 0
        var currentLineIndex: Int = 0
        whileLoop: while currentLineIndex < currentFileLines.count, headLineIndex < headFileLines.count {
            let currentFileLine = currentFileLines[currentLineIndex]
            let headFileLine = headFileLines[headLineIndex]
            var isAddition = false
            for selectedLine in allLinesInHunk {
                if case .addition = selectedLine.type {
                    if selectedLine.newLine == currentLineIndex + 1 {
                        isAddition = true
                        break
                    }
                }
            }

            if headFileLine == currentFileLine && !isAddition {
                // We found two lines which have the same content, and it is not an addition
                result.append(currentFileLine)
                headLineIndex += 1
                currentLineIndex += 1
                continue whileLoop
            } else {
                // lines are not the same

                // is it a deletion, or addition?
                var itsDeletion = false
                var itsAddition = false

                for selectedLine in selectedLines {
                    if case .deletion = selectedLine.type {
                        let deletionLineNumber = Int(selectedLine.oldLine)
                        if deletionLineNumber == headLineIndex + 1 {
                            // we found the deleted change, and it is part of selected lines
                            // this line should not be added to the result
                            // we need to check this line again, currentLineIndex should not move, headIndex should go up
                            itsDeletion = true
                            headLineIndex += 1
                            continue whileLoop
                        }
                    }
                }
                if !itsDeletion {
                    for hunkLine in allLinesInHunk {
                        if case .deletion = hunkLine.type {
                            let deletionLineNumber = Int(hunkLine.oldLine)
                            if deletionLineNumber == headLineIndex + 1 {
                                // we found the deleted change, which is not part of selection
                                // original line should be added to the result
                                // we need to check this line again, currentLineIndex should not move, headIndex should go up
                                result.append(headFileLine)
                                itsDeletion = true
                                headLineIndex += 1
                                continue whileLoop
                            }
                        }
                    }
                }

                if !itsDeletion {
                    // Is it an addition?
                    for selectedLine in selectedLines {
                        if case .addition = selectedLine.type {
                            let additonLineNumber = Int(selectedLine.newLine)
                            if additonLineNumber == currentLineIndex + 1 {
                                // We found the added change, and it is part of selected lines.
                                // This line should be added to the result.
                                // headIndex should not move.
                                result.append(currentFileLine)
                                itsAddition = true
                                currentLineIndex += 1
                                continue whileLoop
                            }
                        }
                    }
                    if !itsAddition {
                        for hunkLine in allLinesInHunk {
                            if case .addition = hunkLine.type {
                                let additonLineNumber = Int(hunkLine.newLine)
                                if additonLineNumber == currentLineIndex + 1 {
                                    // We found the added change, and it is not part of selected lines.
                                    // This line should not be added to the result.
                                    // headIndex should not move.
                                    itsAddition = true
                                    currentLineIndex += 1
                                    continue whileLoop
                                }
                            }
                        }
                    }
                }
                // If we came all the way here, it means that the file is done
                break whileLoop
            }
        }
        return result
    }

    private static func getDiff(
        repository: Repository,
        result: [String],
        headFileLines: [String]?,
        reverse: Bool = false
    ) async throws -> String {
        if let headFileLines {
            let tempResultFilePath = DataManager.appDirPath + "/" + UUID().uuidString
            let tempHeadFilePath = DataManager.appDirPath + "/" + UUID().uuidString
            defer {
                try! FileManager.removeItem(tempResultFilePath)
                try! FileManager.removeItem(tempHeadFilePath)
            }
            try result.joined(separator: "\n").write(toFile: tempResultFilePath, atomically: true, encoding: .utf8)
            try headFileLines.joined(separator: "\n").write(toFile: tempHeadFilePath, atomically: true, encoding: .utf8)
            let diffResult = GitCLI.getDiff(
                repository,
                [tempHeadFilePath, tempResultFilePath],
                reverse: reverse
            )
            switch diffResult {
            case .success(let diff):
                return diff
            case .failure(let error):
                switch error {
                case .noDifferencesFound:
                    return ""
                case .actualError:
                    throw error
                }
            }
        } else {
            let tempResultFilePath = DataManager.appDirPath + "/" + UUID().uuidString
            defer {
                try! FileManager.removeItem(tempResultFilePath)
            }
            try result.joined(separator: "\n").write(toFile: tempResultFilePath, atomically: true, encoding: .utf8)
            let diffResult = GitCLI.getDiff(
                repository,
                ["/dev/null", tempResultFilePath],
                reverse: reverse
            )
            switch diffResult {
            case .success(let diff):
                return diff
            case .failure(let error):
                switch error {
                case .noDifferencesFound:
                    return ""
                case .actualError:
                    throw error
                }
            }
        }
    }
}
