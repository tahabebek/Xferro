//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation
import Observation

@Observable final class DiffHunk: Identifiable, Copyable {
    let id = UUID()

    var parts: [DiffHunkPart]
    let hunk: git_diff_hunk
    let hunkIndex: Int
    let patch: Patch
    let oldFilePath: String?
    let newFilePath: String?
    let status: Diff.Delta.Status
    let repository: Repository

    let oldStart: Int
    let oldLines: Int
    let newStart: Int
    let newLines: Int
    let lineCount: Int
    var hunkHeader: String = ""

    var selectedLinesCount: Int {
        parts.map { $0.selectedLinesCount }.reduce(0, +)
    }

    init(
        hunk: git_diff_hunk,
        hunkIndex: Int,
        patch: Patch,
        oldFilePath: String?,
        newFilePath: String?,
        status: Diff.Delta.Status,
        repository: Repository
    ) {
        self.hunk = hunk
        self.hunkIndex = hunkIndex
        self.patch = patch
        self.oldFilePath = oldFilePath
        self.newFilePath = newFilePath
        self.status = status
        self.parts = []
        self.repository = repository
        self.lineCount = Int(git_patch_num_lines_in_hunk(patch.patch, hunkIndex))
        self.oldStart = Int(hunk.old_start)
        self.oldLines = Int(hunk.old_lines)
        self.newStart = Int(hunk.new_start)
        self.newLines = Int(hunk.new_lines)

        self.hunkHeader = getHunkHeader(hunk: hunk)

        var currentLines: [DiffLine] = []
        var currentPartType = DiffHunkPart.DiffHunkPartType.context
        var partIndex = 0
        for index in 0..<lineCount {
            let line = lineAtIndex(index)
            switch currentPartType {
            case .context:
                if line.isAdditionOrDeletion {
                    parts.append(DiffHunkPart(
                        type: currentPartType,
                        lines: currentLines,
                        indexInHunk: partIndex,
                        oldFilePath: oldFilePath,
                        newFilePath: newFilePath
                    ))
                    partIndex += 1
                    currentPartType = .additionOrDeletion
                    currentLines = [line]
                } else {
                    currentLines += [line]
                }
            case .additionOrDeletion:
                if line.isAdditionOrDeletion {
                    currentLines += [line]
                } else {
                    parts.append(DiffHunkPart(
                        type: currentPartType,
                        lines: currentLines,
                        indexInHunk: partIndex,
                        oldFilePath: oldFilePath,
                        newFilePath: newFilePath
                    ))
                    partIndex += 1
                    currentPartType = .context
                    currentLines = [line]
                }
            }
        }
        parts.append(DiffHunkPart(
            type: currentPartType,
            lines: currentLines,
            indexInHunk: partIndex,
            oldFilePath: oldFilePath,
            newFilePath: newFilePath
        ))
    }

    private func getHunkHeader(hunk: git_diff_hunk) -> String {
        // Create a temporary UnsafeBufferPointer to access the header values
        return withUnsafePointer(to: hunk.header) { headerPtr in
            headerPtr.withMemoryRebound(to: CChar.self, capacity: Int(GIT_DIFF_HUNK_HEADER_SIZE)) { charPtr in
                // Find the length of the null-terminated string within the bounds of header_len
                var length = 0
                while length < Int(hunk.header_len) && charPtr[length] != 0 {
                    length += 1
                }

                // Create a String from the buffer up to the determined length
                return String(cString: charPtr)
            }
        }
    }

    /// Applies just this hunk to the target text.
    /// - parameter text: The target text.
    /// - parameter reversed: True if the target text is the "new" text and the
    /// patch should be reverse-applied.
    /// - returns: The modified hunk of text, or nil if the patch does not match
    /// or if an error occurs.
    func applied(to text: String, reversed: Bool) -> String?
    {
        var lines = text.components(separatedBy: .newlines)
        guard Int(oldStart - 1 + oldLines) <= lines.count
        else { return nil }

        var oldText = [String]()
        var newText = [String]()

        for hunkLine in parts.flatMap(\.lines) {
            let content = hunkLine.text

            switch hunkLine.type {
            case .context:
                oldText.append(content)
                newText.append(content)
            case .addition:
                newText.append(content)
            case .deletion:
                oldText.append(content)
            default:
                break
            }
        }

        let targetLines = reversed ? newText : oldText
        let replacementLines = reversed ? oldText : newText

        let targetLineStart = Int(reversed ? newStart : oldStart) - 1
        let targetLineCount = Int(reversed ? self.newLines : self.oldLines)
        let replaceRange = targetLineStart..<(targetLineStart+targetLineCount)

        if targetLines != Array(lines[replaceRange]) {
            // Patch doesn't match
            return nil
        }
        lines.replaceSubrange(replaceRange, with: replacementLines)

        return lines.joined(separator: text.lineEndingStyle.string)
    }

    func discard()
    {
        repository.discard(hunk: self)
    }

    private func selectedLines() -> [DiffLine] {
        parts.flatMap { $0.lines }.filter { $0.isSelected }
    }

    private func lineAtIndex(_ lineIndex: Int) -> DiffLine {
        var linePointer: UnsafePointer<git_diff_line>?
        let result = git_patch_get_line_in_hunk(&linePointer, patch.patch, hunkIndex, Int(lineIndex))

        guard result == GIT_OK.rawValue, let linePointer else {
            let err = NSError(gitError: result, pointOfFailure: "git_patch_get_line_in_hunk")
            fatalError(err.localizedDescription)
        }
        return DiffLine(linePointer.pointee)
    }

    func copy() -> DiffHunk {
        DiffHunk(
            hunk: hunk,
            hunkIndex: hunkIndex,
            patch: patch,
            oldFilePath: oldFilePath,
            newFilePath: newFilePath,
            status: status,
            repository: repository
        )
    }
}
