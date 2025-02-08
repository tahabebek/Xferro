//
//  CommitsViewModel+HEAD.swift
//  Xferro
//
//  Created by Taha Bebek on 2/8/25.
//

import Foundation

extension CommitsViewModel {
    enum Head: Codable {
        case branch(Branch)
        case tag(TagReference)
        case reference(Reference)

        var oid: OID {
            switch self {
            case .branch(let branch):
                return branch.oid
            case .tag(let tagReference):
                return tagReference.oid
            case .reference(let reference):
                return reference.oid
            }
        }
    }
}
