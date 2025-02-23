//
//  HelperFunctions.swift
//  SwiftSpace
//
//  Created by Taha Bebek on 12/31/24.
//

import CryptoKit
import Foundation

typealias Hash = String
func generateHash(_ content: String) -> Hash {
    let data = Data(content.utf8)
    let hash = Insecure.SHA1.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}

func formattedCurrentDate() -> String {
    Date().hh_colon_mm_colon_ss_space_a_space_dd_dot_MM_dot_YYYY
}

extension Date {
    var dateStringForCommit: String {
        self.hh_colon_mm_colon_ss_space_a_space_dd_dot_MM_dot_YYYY
    }
}

extension String {
}
