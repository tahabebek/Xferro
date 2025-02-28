//
//  DiffHunkPart.swift
//  Xferro
//
//  Created by Taha Bebek on 2/28/25.
//

import Foundation

@Observable final class DiffHunkPart: Equatable, Identifiable {
    static func == (lhs: DiffHunkPart, rhs: DiffHunkPart) -> Bool {
        lhs.type == rhs.type
        && lhs.indexInHunk == rhs.indexInHunk
        && lhs.isSelected == rhs.isSelected
        && lhs.hasSomeSelected == rhs.hasSomeSelected
        && lhs.filePath == rhs.filePath
    }

    var id: String { "\(type.id).\(indexInHunk).\(isSelected).\(hasSomeSelected)" }

    enum DiffHunkPartType: Equatable, Identifiable {
        var id: String {
            switch self {
            case .context:
                "context"
            case .additionOrDeletion:
                "additionOrDeletion"
            }
        }
        case context([DiffLine])
        case additionOrDeletion([DiffLine])
    }
    private var type: DiffHunkPartType
    let indexInHunk: Int
    let filePath: String

    init(type: DiffHunkPartType, indexInHunk: Int, filePath: String) {
        self.type = type
        self.indexInHunk = indexInHunk
        let isSelected = switch type {
        case .context:
            false
        case .additionOrDeletion:
            true
        }
        self.isSelected = isSelected
        self.hasSomeSelected = isSelected

        self.lines = switch type {
        case .context(let lines), .additionOrDeletion(let lines):
            lines
        }
        self.filePath = filePath
        for i in self.lines.indices {
            self.lines[i].indexInPart = i
        }
    }
    var lines: [DiffLine]
    var isSelected: Bool
    var hasSomeSelected: Bool

    func toggleLine(line: DiffLine) {
        switch type {
        case .context:
            break
        case .additionOrDeletion(let lines):
            let linesCopy = lines
            guard let lineIndex = linesCopy.firstIndex(of: line) else { return }
            linesCopy[lineIndex].isSelected.toggle()
            type = .additionOrDeletion(linesCopy)
            refreshSelectedStatus()
        }
    }

    private func selectLine(line: DiffLine, flag: Bool) {
        if case .additionOrDeletion(let lines) = type {
            let linesCopy = lines
            guard let lineIndex = linesCopy.firstIndex(of: line) else { return }
            linesCopy[lineIndex].isSelected = flag
            type = .additionOrDeletion(linesCopy)
        }
    }

    func toggle() {
        for line in lines {
            selectLine(line: line, flag: !isSelected)
        }
        refreshSelectedStatus()
    }

    func refreshSelectedStatus() {
        if case .additionOrDeletion(let lines) = type {
            self.lines = lines
            isSelected = lines.allSatisfy(\.isSelected)
            hasSomeSelected = lines.contains(where: \.isSelected)
            for i in self.lines.indices {
                self.lines[i].indexInPart = i
            }
        }
    }
    }
