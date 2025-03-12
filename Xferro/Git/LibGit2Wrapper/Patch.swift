//
//  Patch.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation

final class Patch
{
    let patch: OpaquePointer // git_patch

    // Data buffers need to be kept because the patch references them
    let oldData, newData: Data?

    init(gitPatch: OpaquePointer)
    {
        self.patch = gitPatch
        self.oldData = nil
        self.newData = nil
    }

    init(repository: Repository, oldBlob: Blob, newBlob: Blob, options: DiffOptions? = nil)
    {
        var oldBlobPointer: OpaquePointer? = nil
        var newBlobPointer: OpaquePointer? = nil

        var oldBlobOid = oldBlob.oid.oid
        var newBlobOid = newBlob.oid.oid
        let oldBlobResult = git_object_lookup_prefix(&oldBlobPointer, repository.pointer, &oldBlobOid, oldBlob.oid.length, GIT_OBJECT_BLOB)
        let newBlobResult = git_object_lookup_prefix(&newBlobPointer, repository.pointer, &newBlobOid, newBlob.oid.length, GIT_OBJECT_BLOB)

        guard oldBlobResult == GIT_OK.rawValue && newBlobResult == GIT_OK.rawValue else {
            fatalError(.unhandledRepositoryError(repository.gitDir))
        }

        let patch = try! OpaquePointer.from { patch in
            DiffOptions.unwrappingOptions(options) {
                git_patch_from_blobs(&patch, oldBlobPointer, nil, newBlobPointer, nil, $0)
            }
        }
        self.patch = patch
        self.oldData = nil
        self.newData = nil
    }

    init(repository: Repository, oldBlob: Blob, newData: Data, options: DiffOptions? = nil)
    {
        var oldBlobPointer: OpaquePointer? = nil
        var oldBlobOid = oldBlob.oid.oid
        let oldBlobResult = git_object_lookup_prefix(&oldBlobPointer, repository.pointer, &oldBlobOid, oldBlob.oid.length, GIT_OBJECT_BLOB)

        guard oldBlobResult == GIT_OK.rawValue else {
            fatalError(.unhandledRepositoryError(repository.gitDir))
        }

        let patch = try! OpaquePointer.from { patch in
            DiffOptions.unwrappingOptions(options) { options in
                newData.withUnsafeBytes { bytes in
                    git_patch_from_blob_and_buffer(
                        &patch,
                        oldBlobPointer,
                        nil,
                        bytes.bindMemory(to: UInt8.self).baseAddress,
                        newData.count,
                        nil,
                        options
                    )
                }
            }
        }

        self.patch = patch
        self.oldData = nil
        self.newData = newData
    }

    init(oldData: Data, newData: Data, options: DiffOptions? = nil)
    {
        let patch = try! OpaquePointer.from({
            (patch) in
            DiffOptions.unwrappingOptions(options) {
                (gitOptions) in
                oldData.withUnsafeBytes {
                    (oldBytes: UnsafeRawBufferPointer) in
                    newData.withUnsafeBytes {
                        (newBytes: UnsafeRawBufferPointer) in
                        git_patch_from_buffers(&patch,
                                               oldBytes.baseAddress, oldData.count, nil,
                                               newBytes.baseAddress, newData.count, nil,
                                               gitOptions)
                    }
                }
            }
        })

        self.patch = patch
        self.oldData = oldData
        self.newData = newData
    }

    deinit
    {
        git_patch_free(patch)
    }

    var hunkCount: Int {
        git_patch_num_hunks(patch)
    }

    var addedLinesCount: Int
    {
        var result: Int = 0

        _ = git_patch_line_stats(nil, &result, nil, patch)
        return result
    }
    var deletedLinesCount: Int
    {
        var result: Int = 0

        _ = git_patch_line_stats(nil, nil, &result, patch)
        return result
    }

    func hunk(
        at index: Int,
        oldFilePath: String? = nil,
        newFilePath: String? = nil,
        status: Diff.Delta.Status,
        repository: Repository
    ) -> DiffHunk?
    {
        guard let hunk: UnsafePointer<git_diff_hunk> = try? .from({
            git_patch_get_hunk(&$0, nil, patch, index)
        })
        else { return nil }

        return DiffHunk(
            hunk: hunk.pointee,
            hunkIndex: index,
            patch: self,
            oldFilePath: oldFilePath,
            newFilePath: newFilePath,
            status: status,
            repository: repository
        )
    }
}
