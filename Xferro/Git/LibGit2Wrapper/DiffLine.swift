//
//  DiffLine.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation

struct DiffLine: Equatable
{
    static func == (lhs: DiffLine, rhs: DiffLine) -> Bool {
        let result = lhs.type == rhs.type
        && lhs.oldLine == rhs.oldLine
        && lhs.newLine == rhs.newLine
        && lhs.lineCount == rhs.lineCount
        && lhs.byteCount == rhs.byteCount
        && lhs.offset == rhs.offset
        && lhs.text == rhs.text
        print(result)
        return result
    }
    let gitDiffLine: git_diff_line
    var isSelected: Bool = false
    var isPartSelected = true

    init(_ gitDiffLine: git_diff_line) {
        self.gitDiffLine = gitDiffLine
        self.isSelected = self.isAdditionOrDeletion
    }

    var type: DiffLineType {
        DiffLineType(rawValue: UInt32(gitDiffLine.origin))
    }
    var oldLine: Int32 {
        gitDiffLine.old_lineno
    }
    var newLine: Int32 {
        gitDiffLine.new_lineno
    }
    var lineCount: Int32 {
        gitDiffLine.num_lines
    }
    var byteCount: Int {
        gitDiffLine.content_len
    }
    var offset: Int64 {
        gitDiffLine.content_offset
    }

    var isAdditionOrDeletion: Bool {
        type == .addition || type == .deletion
    }

    var text: String {
        if let text = NSString(bytes: gitDiffLine.content, length: gitDiffLine.content_len,
                               encoding: String.Encoding.utf8.rawValue) as String? {
            return text.trimmingCharacters(in: .newlines)
        }
        else {
            return ""
        }
    }
}

struct DiffLineType: Equatable {
    static let context = DiffLineType(GIT_DIFF_LINE_CONTEXT)
    static let addition = DiffLineType(GIT_DIFF_LINE_ADDITION)
    static let deletion = DiffLineType(GIT_DIFF_LINE_DELETION)
    static let bothFilesHaveNoLineFeed = DiffLineType(GIT_DIFF_LINE_CONTEXT_EOFNL)
    static let oldHasNoLineFeed = DiffLineType(GIT_DIFF_LINE_ADD_EOFNL)
    static let newHasNoLineFeed = DiffLineType(GIT_DIFF_LINE_DEL_EOFNL)
    static let fileHeader = DiffLineType(GIT_DIFF_LINE_FILE_HDR)
    static let hunkHeader = DiffLineType(GIT_DIFF_LINE_HUNK_HDR)
    static let binary = DiffLineType(GIT_DIFF_LINE_BINARY)

    private let value: UInt32

    init(rawValue value: UInt32) {
        self.value = value
    }

    init(_ lineType: git_diff_line_t) {
        self.value = UInt32(lineType.rawValue)
    }

    var rawValue: UInt32 {
        return value
    }

    var gitDiffLineType: git_diff_line_t {
        return git_diff_line_t(self.value)
    }
}

