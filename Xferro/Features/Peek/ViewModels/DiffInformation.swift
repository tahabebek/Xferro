//
//  DiffInformation.swift
//  Xferro
//
//  Created by Taha Bebek on 3/8/25.
//

import Foundation

protocol DiffInformation: Equatable, Identifiable {
    var hunks: () -> [DiffHunk] { get }
    var checkState: CheckboxState { get set }
    var statusFileName: String { get }
}
