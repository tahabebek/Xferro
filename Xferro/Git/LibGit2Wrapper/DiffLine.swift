//
//  DiffLine.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation
import Observation

@Observable class DiffLine: Identifiable, Equatable
{
    var id: String {
        "\(type.id).\(oldLine).\(newLine).\(isSelected).\(indexInPart)"
    }
    static func == (lhs: DiffLine, rhs: DiffLine) -> Bool {
        lhs.id == rhs.id
    }

    let type: DiffLineType
    let isTracked: Bool
    let gitDiffLine: git_diff_line
    var isSelected: Bool
    var indexInPart: Int = 0

    init(_ gitDiffLine: git_diff_line, isTracked: Bool) {
        self.gitDiffLine = gitDiffLine
        self.type = DiffLineType(origin: gitDiffLine.origin)
        self.oldLine = gitDiffLine.old_lineno
        self.newLine = gitDiffLine.new_lineno
        self.isAdditionOrDeletion = self.type == .addition || self.type == .deletion
        self.isTracked = isTracked
        self.text = if let text = NSString(
            bytes: gitDiffLine.content,
            length: gitDiffLine.content_len,
            encoding: String.Encoding.utf8.rawValue
        ) as String? {
            text.trimmingCharacters(in: .newlines)
        } else {
            ""
        }
        if case .context = type {
            self.isSelected = false
        } else if !isTracked {
            self.isSelected = false
        } else {
            self.isSelected = true
        }
    }

    let oldLine: Int32
    let newLine: Int32
    let isAdditionOrDeletion: Bool
    let text: String
}

enum DiffLineType: Equatable, Hashable {
    var id: String {
        switch self {
        case .addition:
            "+"
        case .deletion:
            "-"
        case .context:
            " "
        case .bothFilesHaveNoLineFeed:
            "="
        case .oldHasNoLineFeed:
            "<"
        case .newHasNoLineFeed:
            ">"
        case .fileHeader:
            "F"
        case .hunkHeader:
            "H"
        case .binary:
            "B"
        }
    }
    case context
    case addition
    case deletion
    case bothFilesHaveNoLineFeed
    case oldHasNoLineFeed
    case newHasNoLineFeed
    case fileHeader
    case hunkHeader
    case binary

    init(origin: CChar) {
        switch origin {
        case Int8(GIT_DIFF_LINE_CONTEXT.rawValue):
            self = .context
        case Int8(GIT_DIFF_LINE_ADDITION.rawValue):
            self = .addition
        case Int8(GIT_DIFF_LINE_DELETION.rawValue):
            self = .deletion
        case Int8(GIT_DIFF_LINE_CONTEXT_EOFNL.rawValue):
            self = .bothFilesHaveNoLineFeed
        case Int8(GIT_DIFF_LINE_ADD_EOFNL.rawValue):
            self = .oldHasNoLineFeed
        case Int8(GIT_DIFF_LINE_DEL_EOFNL.rawValue):
            self = .newHasNoLineFeed
        case Int8(GIT_DIFF_LINE_FILE_HDR.rawValue):
            self = .fileHeader
        case Int8(GIT_DIFF_LINE_HUNK_HDR.rawValue):
            self = .hunkHeader
        case Int8(GIT_DIFF_LINE_BINARY.rawValue):
            self = .binary
        default:
            fatalError(.invalid)
        }
    }

    init(_ lineType: git_diff_line_t) {
        switch lineType {
        case GIT_DIFF_LINE_CONTEXT:
            self = .context
        case GIT_DIFF_LINE_ADDITION:
            self = .addition
        case GIT_DIFF_LINE_DELETION:
            self = .deletion
        case GIT_DIFF_LINE_CONTEXT_EOFNL:
            self = .bothFilesHaveNoLineFeed
        case GIT_DIFF_LINE_ADD_EOFNL:
            self = .oldHasNoLineFeed
        case GIT_DIFF_LINE_DEL_EOFNL:
            self = .newHasNoLineFeed
        case GIT_DIFF_LINE_FILE_HDR:
            self = .fileHeader
        case GIT_DIFF_LINE_HUNK_HDR:
            self = .hunkHeader
        case GIT_DIFF_LINE_BINARY:
            self = .binary
        default:
            fatalError("Invalid git_diff_line_t value: \(lineType.rawValue)")
        }
    }
}


extension DiffLineType: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .context:
            return "Context Line"
        case .addition:
            return "Addition Line (+)"
        case .deletion:
            return "Deletion Line (-)"
        case .bothFilesHaveNoLineFeed:
            return "Both Files Have No Line Feed"
        case .oldHasNoLineFeed:
            return "Old File Has No Line Feed"
        case .newHasNoLineFeed:
            return "New File Has No Line Feed"
        case .fileHeader:
            return "File Header"
        case .hunkHeader:
            return "Hunk Header"
        case .binary:
            return "Binary Content"
        }
    }
}
