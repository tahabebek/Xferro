//
//  Array++.swift
//  SwiftSpace
//
//  Created by Taha Bebek on 12/23/24.
//

extension Array {
    var isNotEmpty: Bool { !isEmpty }
    
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < endIndex else { return nil }
        return self[index]
    }
}
