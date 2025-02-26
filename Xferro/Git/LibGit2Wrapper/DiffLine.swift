//
//  DiffLine.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation

protocol DiffLine
{
    var type: DiffLineType { get }
    var oldLine: Int32 { get }
    var newLine: Int32 { get }
    var lineCount: Int32 { get }
    var byteCount: Int { get }
    var offset: Int64 { get }
    var text: String { get }
}

extension git_diff_line: DiffLine
{
    var type: DiffLineType { DiffLineType(rawValue: UInt32(origin)) }
    public var oldLine: Int32 { old_lineno }
    public var newLine: Int32 { new_lineno }
    public var lineCount: Int32 { num_lines }
    public var byteCount: Int { content_len }
    public var offset: Int64 { content_offset }
    public var text: String
    {
        if let text = NSString(bytes: content, length: content_len,
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

