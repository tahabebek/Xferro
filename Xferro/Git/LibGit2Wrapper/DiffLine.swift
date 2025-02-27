//
//  DiffLine.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation

struct DiffLine: Identifiable, Equatable
{
    var id: String {
        type.rawValue.formatted() + "_\(offset)" + "_\(text)" + "_\(oldLine)" + "_\(newLine)"
    }
    static func == (lhs: DiffLine, rhs: DiffLine) -> Bool {
        lhs.type == rhs.type
        && lhs.oldLine == rhs.oldLine
        && lhs.newLine == rhs.newLine
        && lhs.lineCount == rhs.lineCount
        && lhs.byteCount == rhs.byteCount
        && lhs.offset == rhs.offset
        && lhs.text == rhs.text
    }
    let gitDiffLine: git_diff_line
    var isSelected: Bool = false

    init(_ gitDiffLine: git_diff_line) {
        self.gitDiffLine = gitDiffLine
        self.type = DiffLineType(rawValue: UInt32(gitDiffLine.origin))
        self.oldLine = gitDiffLine.old_lineno
        self.newLine = gitDiffLine.new_lineno
        self.lineCount = gitDiffLine.num_lines
        self.byteCount = gitDiffLine.content_len
        self.offset = gitDiffLine.content_offset
        self.isAdditionOrDeletion = self.type == .addition || self.type == .deletion
        self.text = if let text = NSString(
            bytes: gitDiffLine.content,
            length: gitDiffLine.content_len,
            encoding: String.Encoding.utf8.rawValue
        ) as String? {
            text.trimmingCharacters(in: .newlines)
        } else {
            ""
        }
        self.isSelected = self.isAdditionOrDeletion
    }

    let type: DiffLineType
    let oldLine: Int32
    let newLine: Int32
    let lineCount: Int32
    let byteCount: Int
    let offset: Int64
    let isAdditionOrDeletion: Bool
    let text: String
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

