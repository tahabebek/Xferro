//
//  Diffs.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

struct StatusEntry: CustomDebugStringConvertible {
    var id: String { UUID().uuidString }
    var status: Diff.Status
    var stagedDelta: Diff.Delta?
    var unstagedDelta: Diff.Delta?

    init(from statusEntry: git_status_entry) {
        self.status = Diff.Status(rawValue: statusEntry.status.rawValue)

        if let htoi = statusEntry.head_to_index {
            self.stagedDelta = Diff.Delta(htoi.pointee)
        }

        if let itow = statusEntry.index_to_workdir {
            self.unstagedDelta = Diff.Delta(itow.pointee)
        }
    }

    var debugDescription: String {
        var desc = "StatusEntry(status: \(status)"
        if let stagedDelta { desc += ", stagedDelta: \(stagedDelta)" }
        if let unstagedDelta { desc += ", unstagedDelta: \(unstagedDelta))" }
        return desc
    }
}

struct Diff {

    /// The set of deltas.
    var deltas = [Delta]()

    struct Delta: CustomDebugStringConvertible, Identifiable {
        var id: String { statusName + flags.debugDescription + (oldFile?.path ?? "") + (newFile?.path ?? "") }

        enum Status: UInt32, CustomDebugStringConvertible {
            case unmodified     = 0     /**< no changes */
            case added          = 1     /**< entry does not exist in old version */
            case deleted        = 2     /**< entry does not exist in new version */
            case modified       = 3     /**< entry content changed between old and new */
            case renamed        = 4     /**< entry was renamed between old and new */
            case copied         = 5     /**< entry was copied from another old entry */
            case ignored        = 6     /**< entry is ignored item in workdir */
            case untracked      = 7     /**< entry is untracked item in workdir */
            case typeChange     = 8     /**< type of entry changed between old and new */
            case unreadable     = 9     /**< entry is unreadable */
            case conflicted     = 10    /**< entry in the index is conflicted */

            var debugDescription: String {
                switch self {
                case .unmodified: return "unmodified"
                case .added: return "added"
                case .deleted: return "deleted"
                case .modified: return "modified"
                case .renamed: return "renamed"
                case .copied: return "copied"
                case .ignored: return "ignored"
                case .untracked: return "untracked"
                case .typeChange: return "typeChange"
                case .unreadable: return "unreadable"
                case .conflicted: return "conflicted"
                }
            }
        }

        var status: Status
        var statusName: String
        var flags: Flags
        var oldFile: File?
        var newFile: File?

        init(_ delta: git_diff_delta) {
            self.status = Status(rawValue: delta.status.rawValue)!
            self.statusName = String(UnicodeScalar(UInt8(git_diff_status_char(delta.status))))
            self.flags = Flags(rawValue: delta.flags)
            self.oldFile = File(delta.old_file)
            self.newFile = File(delta.new_file)
        }

        var debugDescription: String {
            var desc = "Delta(status: \(status)"
            if let oldFile { desc += ", oldFile: \(oldFile)" }
            if let newFile { desc += ", newFile: \(newFile)" }
            desc += ", flags: \(flags))"
            return desc
        }
    }

    struct File: CustomDebugStringConvertible {
        var oid: OID
        var path: String
        var size: UInt64
        var flags: Flags
        var mode: UInt32

        init(_ diffFile: git_diff_file) {
            self.oid = OID(diffFile.id)
            let path = diffFile.path
            self.path = path.map(String.init(cString:))!
            self.size = diffFile.size
            self.flags = Flags(rawValue: diffFile.flags)
            self.mode = UInt32(diffFile.mode)
        }

        var debugDescription: String {
            let modeDesc = switch mode {
            case 0o100000: "regular file"
            case 0o040000: "directory"
            case 0o120000: "symbolic link"
            case 0o160000: "gitlink (submodule)"
            default: "unknown"
            }
            return "File(path: \(path), mode: \(String(format:"0%o", mode)) (\(modeDesc)), size: \(size), flags: \(flags), oid: \(oid))"
        }
    }

    struct Status: OptionSet, CustomDebugStringConvertible {
        // This appears to be necessary due to bug in Swift
        // https://bugs.swift.org/browse/SR-3003
        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        let rawValue: UInt32

        static let current                = Status(rawValue: GIT_STATUS_CURRENT.rawValue)
        static let indexNew               = Status(rawValue: GIT_STATUS_INDEX_NEW.rawValue)
        static let indexModified          = Status(rawValue: GIT_STATUS_INDEX_MODIFIED.rawValue)
        static let indexDeleted           = Status(rawValue: GIT_STATUS_INDEX_DELETED.rawValue)
        static let indexRenamed           = Status(rawValue: GIT_STATUS_INDEX_RENAMED.rawValue)
        static let indexTypeChange        = Status(rawValue: GIT_STATUS_INDEX_TYPECHANGE.rawValue)
        static let workTreeNew            = Status(rawValue: GIT_STATUS_WT_NEW.rawValue)
        static let workTreeModified       = Status(rawValue: GIT_STATUS_WT_MODIFIED.rawValue)
        static let workTreeDeleted        = Status(rawValue: GIT_STATUS_WT_DELETED.rawValue)
        static let workTreeTypeChange     = Status(rawValue: GIT_STATUS_WT_TYPECHANGE.rawValue)
        static let workTreeRenamed        = Status(rawValue: GIT_STATUS_WT_RENAMED.rawValue)
        static let workTreeUnreadable     = Status(rawValue: GIT_STATUS_WT_UNREADABLE.rawValue)
        static let ignored                = Status(rawValue: GIT_STATUS_IGNORED.rawValue)
        static let conflicted             = Status(rawValue: GIT_STATUS_CONFLICTED.rawValue)

        var debugDescription: String {
            var components: [String] = []
            if self == .current { return "current" }
            if contains(.indexNew) { components.append("indexNew") }
            if contains(.indexModified) { components.append("stagedModified") }
            if contains(.indexDeleted) { components.append("stagedDeleted") }
            if contains(.indexRenamed) { components.append("stagedRenamed") }
            if contains(.indexTypeChange) { components.append("stagedTypeChange") }
            if contains(.workTreeNew) { components.append("unstagedNew") }
            if contains(.workTreeModified) { components.append("unstagedModified") }
            if contains(.workTreeDeleted) { components.append("unstagedDeleted") }
            if contains(.workTreeTypeChange) { components.append("unstagedTypeChange") }
            if contains(.workTreeRenamed) { components.append("unstagedRenamed") }
            if contains(.workTreeUnreadable) { components.append("unstagedUnreadable") }
            if contains(.ignored) { components.append("ignored") }
            if contains(.conflicted) { components.append("conflicted") }
            return components.joined(separator: ", ")
        }
    }

    struct Flags: OptionSet, CustomDebugStringConvertible {
        // This appears to be necessary due to bug in Swift
        // https://bugs.swift.org/browse/SR-3003
        init(rawValue: UInt32) {
            self.rawValue = rawValue
        }
        let rawValue: UInt32

        static let binary     = Flags(rawValue: 1 << 0)
        static let notBinary  = Flags(rawValue: 1 << 1)
        static let validId    = Flags(rawValue: 1 << 2)
        static let exists     = Flags(rawValue: 1 << 3)

        var debugDescription: String {
            var components: [String] = []
            if contains(.binary) { components.append("binary") }
            if contains(.notBinary) { components.append("notBinary") }
            if contains(.validId) { components.append("validId") }
            if contains(.exists) { components.append("exists") }
            return components.isEmpty ? "[]" : components.joined(separator: ", ")
        }
    }

    /// Create an instance with a libgit2 `git_diff`.
    init(_ pointer: OpaquePointer) {
        for i in 0..<git_diff_num_deltas(pointer) {
            if let delta = git_diff_get_delta(pointer, i) {
                deltas.append(Diff.Delta(delta.pointee))
            }
        }
    }
}
