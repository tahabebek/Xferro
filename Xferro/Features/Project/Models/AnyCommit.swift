//
//  AnyCommit.swift
//  Xferro
//
//  Created by Taha Bebek on 1/13/25.
//

struct AnyCommit: Equatable, Hashable {
    enum Kind {
        case auto
        case manual
    }
    let commit: Commit
    let kind: Kind
    let isMarked: Bool
    var oid: OID { commit.oid }
    
    static func == (lhs: AnyCommit, rhs: AnyCommit) -> Bool {
        lhs.commit == rhs.commit
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(commit)
    }
}
