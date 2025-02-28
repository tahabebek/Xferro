//
//  DiffHunk.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation
import Observation

@Observable final class DiffHunk: Identifiable, Equatable
{
    static func == (lhs: DiffHunk, rhs: DiffHunk) -> Bool {
        lhs.id == rhs.id
    }

    var id: String {
        "\(filePath)\(patch.id).\(hunkIndex)"
    }

    var parts: [DiffHunkPart]
    let hunk: git_diff_hunk
    let hunkIndex: Int
    let patch: Patch
    let filePath: String

    var oldStart: Int32 { hunk.old_start }
    var oldLines: Int32 { hunk.old_lines }
    var newStart: Int32 { hunk.new_start }
    var newLines: Int32 { hunk.new_lines }
    var lineCount: Int { Int(git_patch_num_lines_in_hunk(patch.patch, hunkIndex)) }

    init(
        hunk: git_diff_hunk,
        hunkIndex: Int,
        patch: Patch,
        filePath: String
    ) {
        self.hunk = hunk
        self.hunkIndex = hunkIndex
        self.patch = patch
        self.filePath = filePath
        let lineCount = Int(git_patch_num_lines_in_hunk(patch.patch, hunkIndex))
        self.parts = []
        var currentPart = DiffHunkPart.DiffHunkPartType.context([])
        var partIndex = 0
        for index in 0..<lineCount {
            let line = lineAtIndex(index)
            switch currentPart {
            case .context(let array):
                if line.isAdditionOrDeletion {
                    parts.append(DiffHunkPart(type: currentPart, indexInHunk: partIndex, filePath: filePath))
                    partIndex += 1
                    currentPart = .additionOrDeletion([line])
                } else {
                    currentPart = .context(array + [line])
                }
            case .additionOrDeletion(let array):
                if line.isAdditionOrDeletion {
                    currentPart = .additionOrDeletion(array + [line])
                } else {
                    parts.append(DiffHunkPart(type: currentPart, indexInHunk: partIndex, filePath: filePath))
                    partIndex += 1
                    currentPart = .context([line])
                }
            }
        }
        parts.append(DiffHunkPart(type: currentPart, indexInHunk: partIndex, filePath: filePath))
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

        enumerateLines { line in
            let content = line.text

            switch line.type {
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

    /// Returns true if the hunk can be applied to the given text.
    /// - parameter lines: The target text. This is an array of strings rather
    /// than the raw text to more efficiently query multiple hunks on one file.
    func canApply(to lines: [String]) -> Bool
    {
        guard (oldLines == 0) || (oldStart - 1 + oldLines <= lines.count)
        else { return false }

        var oldText = [String]()

        enumerateLines { line in
            switch line.type {
            case .context, .deletion:
                oldText.append(line.text)
            default:
                break
            }
        }

        // oldStart and oldLines are 0 if the old file is empty
        let targetLineStart = max(Int(oldStart) - 1, 0)
        let targetLineCount = Int(self.oldLines)
        let replaceRange = targetLineStart..<(targetLineStart+targetLineCount)

        return oldText.elementsEqual(lines[replaceRange])
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

    func enumerateLines(_ callback: (DiffLine) -> Void)
    {
        let lineCount = git_patch_num_lines_in_hunk(patch.patch, hunkIndex)

        for lineIndex in 0..<lineCount {
            guard let line: UnsafePointer<git_diff_line> = try? .from({
                git_patch_get_line_in_hunk(&$0, patch.patch, hunkIndex, Int(lineIndex))
            })
            else { continue }

            callback(DiffLine(line.pointee))
        }
    }
}
