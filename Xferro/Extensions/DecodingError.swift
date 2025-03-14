//
//  DecodingError.swift
//  Xferro
//
//  Created by Taha Bebek on 3/14/25.
//

import Foundation

extension DecodingError {
    var context: Context {
        switch self {
        case .dataCorrupted(let context):
            context
        case .keyNotFound(_, let context):
            context
        case .typeMismatch(_, let context):
            context
        case .valueNotFound(_, let context):
            context
        @unknown default:
            Context(codingPath: [], debugDescription: "")
        }
    }
}
