//
//  PatchMaker.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation

final class PatchMaker {
    enum SourceType {
        case blob(Blob)
        case data(Data)

        init(_ blob: (Blob)?) {
            self = blob.map { .blob($0) } ?? .data(Data())
        }
    }

    enum PatchResult {
        case noDifference
        case binary
        case diff(PatchMaker)

        var patchMaker: PatchMaker? {
            switch self {
            case .diff(let maker): return maker
            default: return nil
            }
        }
    }

    let repository: Repository
    let path: String
    let fromSource: SourceType
    let toSource: SourceType

    let contextLines: Int = 3

    private var options: DiffOptions {
        var result = DiffOptions(flags: [])
        result.contextLines = UInt32(contextLines)
        return result
    }

    init(repository: Repository, from: SourceType, to: SourceType, path: String) {
        self.repository = repository
        self.fromSource = from
        self.toSource = to
        self.path = path
    }

    func makePatch() -> Patch {
        switch (fromSource, toSource) {
        case let (.blob(fromBlob), .blob(toBlob)):
            Patch(repository: repository, oldBlob: fromBlob, newBlob: toBlob, options: options)
        case let (.data(fromData), .data(toData)):
            Patch(oldData: fromData, newData: toData, options: options)
        case let (.blob(fromBlob), .data(toData)):
            Patch(repository: repository, oldBlob: fromBlob, newData: toData, options: options)
        case let (.data(fromData), .blob(toBlob)):
            Patch(oldData: fromData, newData: toBlob.data, options: options)
        }
    }
}
