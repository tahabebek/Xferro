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
        print(lhs.id)
        print(rhs.id)
        let result = lhs.id == rhs.id
        print(result)
        return result
    }

    var id: String {
        "\(patch.id).\(hunkIndex).\(parts.map(\.id).joined(separator: ","))"
    }

    struct DiffHunkPart: Equatable, Identifiable {
        static func == (lhs: DiffHunkPart, rhs: DiffHunkPart) -> Bool {
            lhs.type == rhs.type && lhs.index == rhs.index && lhs.isSelected == rhs.isSelected && lhs.hasSomeSelected == rhs.hasSomeSelected
        }

        var id: String { "\(type.id).\(index).\(isSelected).\(hasSomeSelected)" }

        enum DiffHunkPartType: Equatable, Identifiable {
            var id: String {
                switch self {
                case .context(let lines):
                    return lines.map(\.id).joined(separator: ",") + ".context"
                case .additionOrDeletion(let lines):
                    return lines.map(\.id).joined(separator: ",") + ".additionOrDeletion"
                }
            }
            case context([DiffLine])
            case additionOrDeletion([DiffLine])
        }
        var type: DiffHunkPartType
        let index: Int
        init(type: DiffHunkPartType, index: Int) {
            self.type = type
            self.index = index
            self.isSelected = switch type {
            case .context:
                false
            case .additionOrDeletion(let array):
                array.allSatisfy { $0.isSelected }
            }
        }
        var lines: [DiffLine] {
            get {
                switch type {
                case .context(let lines), .additionOrDeletion(let lines):
                    lines
                }
            }
        }

        var isSelected: Bool
        var hasSomeSelected: Bool {
            lines.contains(where: \.isSelected)
        }

        mutating func toggleLine(lineIndex: Int) {
            switch type {
            case .context(let lines):
                var linesCopy = lines
                linesCopy[lineIndex].isSelected.toggle()
                type = .context(linesCopy)
            case .additionOrDeletion(let lines):
                var linesCopy = lines
                linesCopy[lineIndex].isSelected.toggle()
                type = .additionOrDeletion(linesCopy)
            }
        }

        mutating func selectLine(lineIndex: Int, flag: Bool) {
            switch type {
            case .context(let lines):
                var linesCopy = lines
                linesCopy[lineIndex].isSelected = flag
                type = .context(linesCopy)
            case .additionOrDeletion(let lines):
                var linesCopy = lines
                linesCopy[lineIndex].isSelected = flag
                type = .additionOrDeletion(linesCopy)
            }
        }
        mutating func refreshSelectedStatus() {
            isSelected = switch type {
            case .context:
                false
            case .additionOrDeletion(let array):
                array.allSatisfy { $0.isSelected }
            }
        }
    }

    var parts: [DiffHunkPart]

    init(hunk: git_diff_hunk, hunkIndex: Int, patch: Patch) {
        self.hunk = hunk
        self.hunkIndex = hunkIndex
        self.patch = patch
        let lineCount = Int(git_patch_num_lines_in_hunk(patch.patch, hunkIndex))
        self.parts = []
        var currentPart = DiffHunkPart.DiffHunkPartType.context([])
        var partIndex = 0
        for index in 0..<lineCount {
            let line = lineAtIndex(index)
            switch currentPart {
            case .context(let array):
                if line.isAdditionOrDeletion {
                    parts.append(DiffHunkPart(type: currentPart, index: partIndex))
                    partIndex += 1
                    currentPart = .additionOrDeletion([line])
                } else {
                    currentPart = .context(array + [line])
                }
            case .additionOrDeletion(let array):
                if line.isAdditionOrDeletion {
                    currentPart = .additionOrDeletion(array + [line])
                } else {
                    parts.append(DiffHunkPart(type: currentPart, index: partIndex))
                    partIndex += 1
                    currentPart = .context([line])
                }
            }
        }
        parts.append(DiffHunkPart(type: currentPart, index: partIndex))
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

    func toggleSelected(lineIndex: Int, partIndex: Int) {
        parts[partIndex].toggleLine(lineIndex: lineIndex)
        parts[partIndex].refreshSelectedStatus()
    }

    func toggleSelected(partIndex: Int) {
        let isSelected = parts[partIndex].isSelected
        for lineIndex in 0..<parts[partIndex].lines.count {
            parts[partIndex].selectLine(lineIndex: lineIndex, flag: !isSelected)
        }
        parts[partIndex].refreshSelectedStatus()
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

    let hunk: git_diff_hunk
    let hunkIndex: Int
    let patch: Patch

    var oldStart: Int32 { hunk.old_start }
    var oldLines: Int32 { hunk.old_lines }
    var newStart: Int32 { hunk.new_start }
    var newLines: Int32 { hunk.new_lines }
    var lineCount: Int {
        Int(git_patch_num_lines_in_hunk(patch.patch, hunkIndex))
    }

    private func lineAtIndex(_ lineIndex: Int) -> DiffLine {
        var linePointer: UnsafePointer<git_diff_line>?
        let result = git_patch_get_line_in_hunk(&linePointer, patch.patch, hunkIndex, Int(lineIndex))

        guard result == GIT_OK.rawValue, let linePointer else {
            let err = NSError(gitError: result, pointOfFailure: "git_patch_get_line_in_hunk")
            fatalError(err.localizedDescription)
        }
        return DiffLine(linePointer.pointee, index: lineIndex)
    }

    func enumerateLines(_ callback: (DiffLine) -> Void)
    {
        let lineCount = git_patch_num_lines_in_hunk(patch.patch, hunkIndex)

        for lineIndex in 0..<lineCount {
            guard let line: UnsafePointer<git_diff_line> = try? .from({
                git_patch_get_line_in_hunk(&$0, patch.patch, hunkIndex, Int(lineIndex))
            })
            else { continue }

            callback(DiffLine(line.pointee, index: Int(lineIndex)))
        }
    }
}
