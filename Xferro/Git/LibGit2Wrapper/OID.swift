//
//  OID.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

struct OID: Equatable, Identifiable {
    var id: String { description }
    // MARK: - Initializers

    /// Create an instance from a hex formatted string.
    ///
    /// string - A 40-byte hex formatted string.
    init?(string: String) {
        self.length = string.lengthOfBytes(using: String.Encoding.utf8)

        let pointer = UnsafeMutablePointer<git_oid>.allocate(capacity: length)
        defer { pointer.deallocate() }

        let result = git_oid_fromstrn(pointer, string, length)
        if result < GIT_OK.rawValue {
            return nil
        }

        oid = pointer.pointee
        self.debugOID = String(Self.desc(length: Int(GIT_OID_SHA1_HEXSIZE), oid: oid).prefix(7))
    }

    /// Create an instance from a libgit2 `git_oid`.
    init(_ oid: git_oid) {
        self.oid = oid
        self.length = size_t(GIT_OID_SHA1_HEXSIZE)
        self.debugOID = String(Self.desc(length: Int(GIT_OID_SHA1_HEXSIZE), oid: oid).prefix(7))
    }

    // MARK: - Properties

    let oid: git_oid
    let debugOID: String
    let length: size_t

    var isShort: Bool {
        return length < GIT_OID_SHA1_HEXSIZE
    }

    var isZero: Bool {
        var oid = self.oid
        return git_oid_is_zero(&oid) == 1
    }
}

extension OID: CustomStringConvertible {
    var description: String {
        return desc(length: Int(GIT_OID_SHA1_HEXSIZE))
    }

    func desc(length: Int) -> String {
        Self.desc(length: length, oid: oid)
    }

    static func desc(length: Int, oid: git_oid) -> String {
        var oid = oid
        let string = UnsafeMutablePointer<Int8>.allocate(capacity: length)
        defer { string.deallocate() }
        git_oid_nfmt(string, length, &oid)
        return String(bytes: string, count: length)!
    }
}

extension OID: Hashable {
    func hash(into hasher: inout Hasher) {
        withUnsafeBytes(of: oid.id) {
            hasher.combine(bytes: $0)
        }
    }

    public static func == (lhs: OID, rhs: OID) -> Bool {
        var left = lhs.oid
        var right = rhs.oid
        return git_oid_cmp(&left, &right) == 0
    }
}

extension OID: Codable {
    enum CodingKeys: String, CodingKey {
        case oid
    }

    // Convert `git_oid` to a hex string for encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        var mutableOid = oid
        let oidHexString = String(cString: git_oid_tostr_s(&mutableOid))
        try container.encode(oidHexString, forKey: .oid)
    }

    // Decode `git_oid` from a hex string
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let oidHexString = try container.decode(String.self, forKey: .oid)
        self.init(string: oidHexString)!
    }
}
