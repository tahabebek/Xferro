//
//  SelectedLinesDiffMaker.swift
//  Xferro
//
//  Created by Taha Bebek on 3/7/25.
//

import Foundation

enum SelectedLinesDiffMaker {
    static func makeDiff(
        repository: Repository,
        filePath: String,
        hunk: DiffHunk,
        allHunks: [DiffHunk]
    ) async throws -> String {
        let headFileContent = GitCLI.executeGit(repository, ["show", "HEAD:\(filePath)"])
        let headFileLines = headFileContent.lines
        let selectedLines = hunk.parts.flatMap(\.lines).filter(\.isSelected)
        let allLinesInHunk = allHunks.flatMap(\.parts).flatMap((\.lines)).filter(\.isAdditionOrDeletion)

        let path = repository.workDir.appendingPathComponent(filePath).path
        if FileManager.fileExists(path) {
            let currentFileLines = try String(contentsOfFile: path, encoding: .utf8).lines
            var result: [String] = []
            var headLineIndex: Int = 0
            var currentLineIndex: Int = 0
            whileLoop: while currentLineIndex < currentFileLines.count {
                let currentFileLine = currentFileLines[currentLineIndex]
                if headFileLines.count >= currentLineIndex {
                    let headFileLine = headFileLines[headLineIndex]
                    if currentLineIndex == 506 {
                        print("debug from here")
                    }
                    if headFileLine == currentFileLine {
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
                        // If we came all the way here, it means this line was handled by
                        // the coincidence of currentLine and headLine being the same in
                        // different locations. We can move on to the next line.
                        currentLineIndex += 1
                    }
                }
                else {
                    // This means there are trailing lines in the curent file,
                    // which may be out of headIndex because of additions.
                    var itsInTheHunk = false
                    for hunkLine in allLinesInHunk {
                        if case .addition = hunkLine.type {
                            let additonLineNumber = Int(hunkLine.newLine)
                            if additonLineNumber == currentLineIndex + 1 {
                                // We found the added change in the hunk
                                itsInTheHunk = true
                                for selectedLine in selectedLines {
                                    if case .addition = selectedLine.type {
                                        let additonLineNumber = Int(selectedLine.newLine)
                                        if additonLineNumber == currentLineIndex + 1 {
                                            // We found the added change, and it is part of selected lines.
                                            // This line should be added to the result.
                                            // headIndex should not move.
                                            result.append(currentFileLine)
                                            break
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if !itsInTheHunk {
                        // This means the trailing line is not an addition.
                        // Just add it to the result since it is an unchanged line.
                        result.append(currentFileLine)
                    }
                    currentLineIndex += 1
                }
            }
            return try await getDiff(repository: repository, result: result, headFileContent: headFileContent)
        }
        else {
            // this means that the file deleted
            let selectedLines = hunk.parts.flatMap(\.lines).filter(\.isSelected)
            if selectedLines.isEmpty {
                fatalError(.invalid)
            }
            var result = [String]()

            for selectedLine in selectedLines {
                if case .deletion = selectedLine.type {
                    result.append(selectedLine.text)
                } else {
                    fatalError(.invalid)
                }
            }
            return try await getDiff(repository: repository, result: result, headFileContent: headFileContent)
        }
    }

    private static func getDiff(repository: Repository, result: [String], headFileContent: String) async throws -> String {
        let tempResultFilePath = DataManager.appDirPath + "/" + UUID().uuidString
        let tempHeadFilePath = DataManager.appDirPath + "/" + UUID().uuidString
        defer {
            try! FileManager.removeItem(tempResultFilePath)
            try! FileManager.removeItem(tempHeadFilePath)
        }
        try result.joined(separator: "\n").write(toFile: tempResultFilePath, atomically: true, encoding: .utf8)
        try headFileContent.write(toFile: tempHeadFilePath, atomically: true, encoding: .utf8)
        return DiffCLI.executeDiff(repository, [tempHeadFilePath, tempResultFilePath])
    }
}
