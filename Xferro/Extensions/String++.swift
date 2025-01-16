//
//  String++.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

extension String {
    public var isNotEmptyOrWhitespace: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}
