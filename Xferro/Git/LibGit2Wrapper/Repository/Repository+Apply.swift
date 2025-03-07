//
//  Repository+Apply.swift
//  Xferro
//
//  Created by Taha Bebek on 3/1/25.
//

import Foundation

extension Repository {
    func discard(delta: Diff.Delta, hunk: DiffHunk)
    {
        var encoding = String.Encoding.utf8
        switch delta.status {
        case .added, .copied:
            guard let url = delta.newFileURL else {
                fatalError(.invalid)
            }
            if FileManager.fileExists(url.path) {
                if url.isDirectory {
                    GitCLI.executeGit(self, ["restore", url.appendingPathComponent("*").path])
                } else {
                    GitCLI.executeGit(self, ["restore", url.path])
                }
                try? FileManager.removeItem(url.path)
                stage(path: delta.newFilePath!).mustSucceed()
            } else {
                fatalError(.invalid)
            }
        case .modified, .renamed:
            guard let url = delta.newFileURL else {
                fatalError(.invalid)
            }
            do {
                if FileManager.fileExists(url.path) {
                    let fileText = try String(contentsOf: url, usedEncoding: &encoding)
                    guard let result = hunk.applied(to: fileText, reversed: true) else {
                        fatalError(.unknown)
                    }
                    try result.write(to: url, atomically: true, encoding: encoding)
                } else {
                    fatalError(.invalid)
                }
            } catch {
                fatalError(error.localizedDescription)
            }
        case .deleted:
            guard let url = delta.oldFileURL else {
                fatalError(.invalid)
            }
            if !FileManager.fileExists(url.path) {
                if url.isDirectory {
                    GitCLI.executeGit(self, ["restore", url.appendingPathComponent("*").path])
                } else {
                    GitCLI.executeGit(self, ["restore", url.path])
                }
            } else {
                fatalError(.invalid)
            }
        case .untracked:
            guard let url = delta.newFileURL else {
                fatalError(.invalid)
            }
            if FileManager.fileExists(url.path) {
                try! FileManager.removeItem(url.path)
            } else {
                fatalError(.invalid)
            }
        case .typeChange:
            guard let oldFileURL = delta.oldFileURL, let newFileURL = delta.newFileURL else {
                fatalError(.invalid)
            }
            do {
                try FileManager.moveItem(oldFileURL, to: newFileURL)
            } catch {
                fatalError(error.localizedDescription)
            }
        case .unreadable, .ignored, .unmodified:
            fatalError(.invalid)
        case .conflicted:
            fatalError(.unimplemented)
        }
    }
    
    func status(of file: String) throws -> (DeltaStatus, DeltaStatus)
    {
        var statusFlags: UInt32 = 0
        let result = git_status_file(&statusFlags, self.pointer, file)
        guard result == GIT_OK.rawValue else {
            fatalError(.unknown)
        }
        
        let flags = git_status_t(statusFlags)
        var unstagedChange = DeltaStatus.unmodified
        var stagedChange = DeltaStatus.unmodified
        
        switch flags {
        case _ where flags.contains(GIT_STATUS_WT_NEW):
            unstagedChange = .untracked
        case _ where flags.contains(GIT_STATUS_WT_MODIFIED),
            _ where flags.contains(GIT_STATUS_WT_TYPECHANGE):
            unstagedChange = .modified
        case _ where flags.contains(GIT_STATUS_WT_DELETED):
            unstagedChange = .deleted
        case _ where flags.contains(GIT_STATUS_WT_RENAMED):
            unstagedChange = .renamed
        case _ where flags.contains(GIT_STATUS_IGNORED):
            unstagedChange = .ignored
        case _ where flags.contains(GIT_STATUS_CONFLICTED):
            unstagedChange = .conflict
            // ignoring GIT_STATUS_WT_UNREADABLE
        default:
            break
        }
        
        switch flags {
        case _ where flags.contains(GIT_STATUS_INDEX_NEW):
            stagedChange = .added
        case _ where flags.contains(GIT_STATUS_INDEX_MODIFIED),
            _ where flags.contains(GIT_STATUS_WT_TYPECHANGE):
            stagedChange = .modified
        case _ where flags.contains(GIT_STATUS_INDEX_DELETED):
            stagedChange = .deleted
        case _ where flags.contains(GIT_STATUS_INDEX_RENAMED):
            stagedChange = .renamed
        default:
            break
        }
        
        return (unstagedChange, stagedChange)
    }


    /*
     The --cached flag is important in these commands for different reasons:
     For git diff:

     With --cached: Shows changes between the index and HEAD (staged changes)
     Without --cached: Shows changes between the working directory and the index (unstaged changes)

     For git apply:

     With --cached: Applies changes to the index (staging area) without modifying the working directory files
     Without --cached: Applies changes to files in the working directory

     So when implementing line-level operations:
     We use git diff without --cached to get the unstaged changes
     We use git apply --cached to apply the selected lines to the index (staging them)

     In unstageSelectedLines:

     We use git diff --cached to get the staged changes
     We use git apply --cached --reverse to unapply the selected lines from the index (unstaging them)

     The --cached flag is essential for making sure these operations affect the staging area (index) rather than your working files. This allows you to stage/unstage changes without modifying the actual content of your files.

     The trailing dash (-) in the command git apply --cached - is a special character that tells Git to read the patch content from standard input (stdin) rather than from a file.
     */

    func stageSelectedLines(
        filePath: String,
        hunk: DiffHunk,
        allHunks: [DiffHunk]
    ) async throws {
        let headFileLines = GitCLI.executeGit(self, ["show", "HEAD:\(filePath)"]).lines
        let selectedLines = hunk.parts.flatMap(\.lines).filter(\.isSelected)
        let allLinesInHunk = allHunks.flatMap(\.parts).flatMap((\.lines)).filter(\.isAdditionOrDeletion)

        let path = workDir.appendingPathComponent(filePath).path
        if FileManager.fileExists(path) {
            do {
                let currentFileLines = try String(contentsOfFile: path, encoding: .utf8).lines
                var result: [String] = []
                var headLineIndex: Int = 0
                var currentLineIndex: Int = 0
                whileLoop: while currentLineIndex < currentFileLines.count {
                    let currentFileLine = currentFileLines[currentLineIndex]
                    if headFileLines.count >= currentLineIndex {
                        let headFileLine = headFileLines[headLineIndex]
                        if currentLineIndex == 506 {
                            print("debug from here")
                        }
                        if headFileLine == currentFileLine {
                            result.append(currentFileLine)
                            headLineIndex += 1
                            currentLineIndex += 1
                            continue whileLoop
                        } else {
                            // lines are not the same

                            // is it a deletion, or addition?
                            var itsDeletion = false
                            var itsAddition = false

                            for selectedLine in selectedLines {
                                if case .deletion = selectedLine.type {
                                    let deletionLineNumber = Int(selectedLine.oldLine)
                                    if deletionLineNumber == headLineIndex + 1 {
                                        // we found the deleted change, and it is part of selected lines
                                        // this line should not be added to the result
                                        // we need to check this line again, currentLineIndex should not move, headIndex should go up
                                        itsDeletion = true
                                        headLineIndex += 1
                                        continue whileLoop
                                    }
                                }
                            }
                            if !itsDeletion {
                                for hunkLine in allLinesInHunk {
                                    if case .deletion = hunkLine.type {
                                        let deletionLineNumber = Int(hunkLine.oldLine)
                                        if deletionLineNumber == headLineIndex + 1 {
                                            // we found the deleted change, which is not part of selection
                                            // original line should be added to the result
                                            // we need to check this line again, currentLineIndex should not move, headIndex should go up
                                            result.append(headFileLine)
                                            itsDeletion = true
                                            headLineIndex += 1
                                            continue whileLoop
                                        }
                                    }
                                }
                            }

                            if !itsDeletion {
                                // is it an addition?
                                for selectedLine in selectedLines {
                                    if case .addition = selectedLine.type {
                                        let additonLineNumber = Int(selectedLine.newLine)
                                        if additonLineNumber == currentLineIndex + 1 {
                                            // we found the added change, and it is part of selected lines
                                            // this line should be added to the result
                                            // headIndex should not move
                                            result.append(currentFileLine)
                                            itsAddition = true
                                            currentLineIndex += 1
                                            continue whileLoop
                                        }
                                    }
                                }
                                if !itsAddition {
                                    for hunkLine in allLinesInHunk {
                                        if case .addition = hunkLine.type {
                                            let additonLineNumber = Int(hunkLine.newLine)
                                            if additonLineNumber == currentLineIndex + 1 {
                                                // we found the added change, and it is not part of selected lines
                                                // this line should not be added to the result
                                                // headIndex should not move
                                                itsAddition = true
                                                currentLineIndex += 1
                                                continue whileLoop
                                            }
                                        }
                                    }
                                }
                            }
                            // if we came all the way here, it means this line was handled by
                            // the coincidence of currentLine and headLine being the same in
                            // different locations
                            // we can move on to the next line
                            currentLineIndex += 1
                        }
                    }
                    else {
                        // this means there are trailing lines, which may be out of headIndex
                        // because of additions
                        var itsInTheHunk = false
                        for hunkLine in allLinesInHunk {
                            if case .addition = hunkLine.type {
                                let additonLineNumber = Int(hunkLine.newLine)
                                if additonLineNumber == currentLineIndex + 1 {
                                    // we found the added change in the hunk
                                    itsInTheHunk = true
                                    for selectedLine in selectedLines {
                                        if case .addition = selectedLine.type {
                                            let additonLineNumber = Int(selectedLine.newLine)
                                            if additonLineNumber == currentLineIndex + 1 {
                                                // we found the added change, and it is part of selected lines
                                                // this line should be added to the result
                                                // headIndex should not move
                                                result.append(currentFileLine)
                                                break
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if !itsInTheHunk {
                            result.append(currentFileLine)
                        }
                        currentLineIndex += 1
                    }
                }
                let tempResultFilePath = DataManager.appDirPath + "/" + UUID().uuidString
                let tempHeadFilePath = DataManager.appDirPath + "/" + UUID().uuidString
                try result.joined(separator: "\n").write(toFile: tempResultFilePath, atomically: true, encoding: .utf8)
                try headFileLines.joined(separator: "\n").write(toFile: tempHeadFilePath, atomically: true, encoding: .utf8)
                let diff = DiffCLI.executeDiff(self, [tempHeadFilePath, tempResultFilePath])

                print(diff)
            } catch {
                fatalError(error.localizedDescription)
            }
        }
//        let selectedLines = hunk.parts.flatMap(\.lines).filter(\.isSelected)
//        let allLinesInTheHunk = hunk.parts.flatMap(\.lines)
//        let allLinesInAllHunks = allHunks.flatMap(\.parts).flatMap(\.lines)
//
//        for selectedLine in selectedLines {
//            // Get the index of the selected line in the full diff
//            guard let selectedIndex = allLinesInTheHunk.firstIndex(where: { $0 == selectedLine }) else {
//                continue
//            }
//
//            // Determine the number of context lines to collect
//            let contextSize = 3
//
//            // Collect context lines before the change
//            var beforeContextLines: [String] = []
//            var beforeIdx = selectedIndex - 1
//            var beforeCount = 0
//
//            while beforeIdx >= 0 && beforeCount < contextSize {
//                let line = allLinesInTheHunk[beforeIdx]
//                // Only use context and deletion lines for context
//                if line.type == .context || line.type == .fileHeader || line.type == .hunkHeader {
//                    // Skip hunk headers and file headers in the actual context lines
//                    if line.type == .context {
//                        beforeContextLines.insert(line.text, at: 0) // Insert at beginning to maintain order
//                        beforeCount += 1
//                    }
//                } else if line.type != .addition {
//                    // Skip addition lines when collecting context before a change
//                    // Other line types might be included as needed
//                    beforeContextLines.insert(line.text, at: 0)
//                    beforeCount += 1
//                }
//
//                beforeIdx -= 1
//            }
//
//            // Collect context lines after the change
//            var afterContextLines: [String] = []
//            var afterIdx = selectedIndex + 1
//            var afterCount = 0
//
//            while afterIdx < allLinesInTheHunk.count && afterCount < contextSize {
//                let line = allLinesInTheHunk[afterIdx]
//                // Only use context and deletion lines for context
//                if line.type == .context || line.type == .fileHeader || line.type == .hunkHeader {
//                    // Skip hunk headers and file headers in the actual context lines
//                    if line.type == .context {
//                        afterContextLines.append(line.text)
//                        afterCount += 1
//                    }
//                } else if line.type != .addition {
//                    // Skip addition lines when collecting context after a change
//                    // Other line types might be included as needed
//                    afterContextLines.append(line.text)
//                    afterCount += 1
//                }
//
//                afterIdx += 1
//            }
//
//            // Calculate the original line number
//            let originalLineNumber = calculateOriginalLineNumber(for: selectedLine, in: allLinesInAllHunks)
//
//            // Generate patch headers
//            let headers = generatePatchHeader(
//                filePath: filePath,
//                selectedLine: selectedLine,
//                originalLineNumber: originalLineNumber,
//                beforeContextLines: beforeContextLines,
//                afterContextLines: afterContextLines
//            )
//
//            // Build the complete patch
//            var patchContent: [String] = []
//            patchContent.append(contentsOf: headers)
//            patchContent.append(contentsOf: beforeContextLines)
//            patchContent.append(selectedLine.text) // The actual changed line
//            patchContent.append(contentsOf: afterContextLines)
//
//            let patch = patchContent.joined(separator: "\n")
//
//            // Now we have a properly formatted patch for this specific change
//            print("Patch for line \(originalLineNumber):\n\(patch)")
//
//            // Write to a file if needed
//            try? patch.write(to: URL(fileURLWithPath: "patch_for_line_\(originalLineNumber).diff"),
//                             atomically: true,
//                             encoding: .utf8)
//        }
    }

    func calculateOriginalLineNumber(for selectedLine: DiffLine, in allLines: [DiffLine]) -> Int {
        // Find the position of the selected line in the diff
        guard let selectedIndex = allLines.firstIndex(where: { $0 == selectedLine }) else {
            return -1 // Line not found
        }

        // Find the most recent hunk header before this line
        var hunkHeaderIndex = -1
        for i in (0..<selectedIndex).reversed() {
            if allLines[i].type == .hunkHeader {
                hunkHeaderIndex = i
                break
            }
        }

        // If no hunk header was found, we can't determine the line number
        guard hunkHeaderIndex >= 0 else {
            return -1
        }

        // Parse the hunk header to get the starting line numbers
        // Format: "@@ -X,Y +A,B @@"
        let hunkHeader = allLines[hunkHeaderIndex].text
        guard let headerMatch = hunkHeader.range(of: "@@ -(\\d+),(\\d+) \\+(\\d+),(\\d+) @@", options: .regularExpression) else {
            return -1
        }

        let headerString = String(hunkHeader[headerMatch])
        let components = headerString.components(separatedBy: CharacterSet(charactersIn: " -,+@"))
            .filter { !$0.isEmpty }

        guard components.count >= 4,
              let originalStartLine = Int(components[0]),
              let newStartLine = Int(components[2]) else {
            return -1
        }

        // Calculate how many lines we've moved from the hunk start to our selected line
        var originalLineOffset = 0
        var currentOriginalLine = originalStartLine

        // Count lines from hunk header to our selected line
        for i in (hunkHeaderIndex + 1)..<selectedIndex {
            switch allLines[i].type {
            case .context:
                // Context lines exist in both original and new file
                currentOriginalLine += 1
            case .deletion:
                // Deletion lines only exist in the original file
                currentOriginalLine += 1
            case .addition:
                // Addition lines don't exist in the original file, so don't increment
                break
            default:
                break
            }
        }

        // Handle the selected line itself
        switch selectedLine.type {
        case .addition:
            // For additions, we return the line where it should be inserted in the original file
            // This is the current original line number (no increment needed)
            return currentOriginalLine
        case .deletion:
            // For deletions, we return the line that should be deleted in the original file
            // This is the current line in the original file
            return currentOriginalLine
        case .context:
            // For context lines, just return their position in the original file
            return currentOriginalLine
        default:
            return -1
        }
    }


    func generatePatchHeader(
        filePath: String,
        selectedLine: DiffLine,
        originalLineNumber: Int,
        beforeContextLines: [String],
        afterContextLines: [String]
    ) -> [String] {

        var headers: [String] = []

        // File headers
        headers.append("--- a/\(filePath)")
        headers.append("+++ b/\(filePath)")

        // Calculate hunk header values
        let beforeCount = beforeContextLines.count
        let afterCount = afterContextLines.count
        let totalContextCount = beforeCount + afterCount

        // Start at the line where we should insert the change
        let originalStartLine = max(1, originalLineNumber - beforeCount)
        let newStartLine = originalStartLine // Usually the same for single changes

        var originalLineCount = totalContextCount
        var newLineCount = totalContextCount

        // Adjust line counts based on the type of change
        if selectedLine.type == .addition {
            // For addition, new file has one more line
            newLineCount += 1
        } else if selectedLine.type == .deletion {
            // For deletion, original file has one more line
            originalLineCount += 1
        }

        // Format the hunk header
        let hunkHeader = "@@ -\(originalStartLine),\(originalLineCount) +\(newStartLine),\(newLineCount) @@"
        headers.append(hunkHeader)

        return headers
    }

    func unstageSelectedLines(
        filePath: String,
        hunk: DiffHunk,
        allHunks: [DiffHunk]
    ) async throws {
        // Get the staged diff for the file
        let diffOutput = GitCLI.executeGit(self, ["diff", "--cached", "--no-color", "--no-ext-diff", filePath])
        
        if diffOutput.isEmpty {
            print("No staged changes found in \(filePath)")
            return
        }
        
        // The rest of the implementation follows the same pattern as stageSelectedLines
        // but using reverse application and looking at staged changes
        
        // We'll implement this fully later as needed
        throw NSError(domain: "GitError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unstaging is not yet implemented for the new DiffLine type"])
    }
    
    func stageHunk(filePath: String, hunkIndex: Int) async throws
    {
        var index: OpaquePointer?
        var diff: OpaquePointer?
        var patch: OpaquePointer?

        guard git_repository_index(&index, pointer) == 0 else {
            fatalError(.unexpected)
        }
        defer { git_index_free(index) }

        // Create a diff between working directory and index
        var opts = git_diff_options()
        git_diff_options_init(&opts, UInt32(GIT_DIFF_OPTIONS_VERSION))

        try filePath.withCString { cstr in
            let strPtr = strdup(cstr)
            var strarray = git_strarray()
            strarray.count = 1

            let strPtrArray = UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: 1)
            strPtrArray[0] = strPtr
            strarray.strings = strPtrArray

            opts.pathspec = strarray

            // Create diff
            if git_diff_index_to_workdir(&diff, pointer, index, &opts) == 0 {
                // Successfully created diff, continue processing...

                // Free memory after diff is created
                free(strPtr)
                strPtrArray.deallocate()

                // Process diff and hunks...
                let numDeltas = git_diff_num_deltas(diff)
                if numDeltas > 0 {
                    // Get the patch for the first delta (or find the specific one)
                    var deltaIndex = 0
                    if numDeltas > 1 {
                        for i in 0..<numDeltas {
                            let delta = git_diff_get_delta(diff, i)
                            if let path = delta?.pointee.new_file.path, String(cString: path) == filePath {
                                deltaIndex = Int(i)
                                break
                            }
                        }
                    }

                    if git_patch_from_diff(&patch, diff, deltaIndex) == 0 {
                        defer { git_patch_free(patch) }

                        // Process the patch and apply the hunk
                        let numHunks = git_patch_num_hunks(patch)
                        if hunkIndex >= 0 && hunkIndex < numHunks {
                            var hunk: UnsafePointer<git_diff_hunk>?
                            var numHunkLines: Int = 0

                            if git_patch_get_hunk(&hunk, &numHunkLines, patch, hunkIndex) == 0 {
                                // Convert patch to buffer
                                var buffer = git_buf()
                                // Initialize with zeros (replacement for git_buf_init)
                                buffer.ptr = nil
                                buffer.size = 0

                                if git_patch_to_buf(&buffer, patch) == 0 {
                                    // Set up apply options
                                    var applyOpts = git_apply_options()
                                    git_apply_options_init(&applyOpts, UInt32(GIT_APPLY_OPTIONS_VERSION))

                                    // Allocate memory for the hunk context
                                    let contextPtr = UnsafeMutablePointer<HunkContext>.allocate(capacity: 1)
                                    contextPtr.initialize(to: HunkContext(targetHunkIndex: hunkIndex, currentHunkIndex: 0))
                                    defer { contextPtr.deallocate() }

                                    // Set up the callback and payload
                                    applyOpts.hunk_cb = hunkSelectionCallback
                                    applyOpts.payload = UnsafeMutableRawPointer(contextPtr)


                                    // Apply the diff
                                    if git_apply(pointer, diff, GIT_APPLY_LOCATION_INDEX, &applyOpts) == 0 {
                                        // Write the index
                                        if git_index_write(index) != 0 {
                                            throw StageHunkError.indexWrite
                                        }
                                    } else {
                                        throw StageHunkError.patchApplication
                                    }
                                } else {
                                    throw StageHunkError.patchConversion
                                }
                            } else {
                                throw StageHunkError.hunkAccess
                            }
                        } else {
                            throw StageHunkError.invalidHunkIndex
                        }
                    } else {
                        throw StageHunkError.patchCreation
                    }
                } else {
                    throw StageHunkError.noChanges
                }
            } else {
                // Clean up if diff creation failed
                free(strPtr)
                strPtrArray.deallocate()
                throw StageHunkError.diffCreation
            }
        }
    }
    
    // Unstage a specific hunk from a file
    func unstageHunk(filePath: String, hunkIndex: Int) async throws {
        var index: OpaquePointer?
        var diff: OpaquePointer?
        var patch: OpaquePointer?

        // Get the repository index
        guard git_repository_index(&index, pointer) == 0 else {
            throw StageHunkError.indexAccess
        }
        defer { git_index_free(index) }

        // Get the current state of the index (before any modifications)
        var originalIndex: OpaquePointer?
        guard git_index_new(&originalIndex) == 0 else {
            throw StageHunkError.indexCreation
        }
        defer { git_index_free(originalIndex) }

        // Copy all entries from the repository index to our original index copy
        let entriesCount = git_index_entrycount(index)
        for i in 0..<entriesCount {
            if let entry = git_index_get_byindex(index, i) {
                git_index_add(originalIndex, entry)
            }
        }

        // Get HEAD for comparison
        var headOid = git_oid()
        var headCommit: OpaquePointer?
        var headTree: OpaquePointer?

        guard git_reference_name_to_id(&headOid, pointer, "HEAD") == 0,
              git_commit_lookup(&headCommit, pointer, &headOid) == 0,
              git_commit_tree(&headTree, headCommit) == 0 else {
            throw StageHunkError.headReference
        }
        defer {
            git_tree_free(headTree)
            git_commit_free(headCommit)
        }

        // 1. Create a temporary index with only HEAD (no staged changes)
        var tempIndex: OpaquePointer?
        guard git_index_new(&tempIndex) == 0 else {
            throw StageHunkError.indexCreation
        }
        defer { git_index_free(tempIndex) }

        // Read the tree into the temporary index
        guard git_index_read_tree(tempIndex, headTree) == 0 else {
            throw StageHunkError.treeRead
        }

        // 2. Create a diff between HEAD (temp index) and current index (with staged changes)
        var opts = git_diff_options()
        git_diff_options_init(&opts, UInt32(GIT_DIFF_OPTIONS_VERSION))

        // Set pathspec to focus only on our target file
        try filePath.withCString { cstr in
            let strPtr = strdup(cstr)
            var strarray = git_strarray()
            strarray.count = 1

            let strPtrArray = UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>.allocate(capacity: 1)
            strPtrArray[0] = strPtr
            strarray.strings = strPtrArray

            opts.pathspec = strarray

            // Create diff between temp index (HEAD) and current index
            if git_diff_index_to_index(&diff, pointer, tempIndex, index, &opts) == 0 {
                // Free memory after diff is created
                free(strPtr)
                strPtrArray.deallocate()

                defer { git_diff_free(diff) }

                // 3. Get the patch and find our target hunk
                if git_patch_from_diff(&patch, diff, 0) == 0 {
                    defer { git_patch_free(patch) }

                    let numHunks = git_patch_num_hunks(patch)
                    if hunkIndex >= 0 && hunkIndex < numHunks {
                        // 4. Here's our key approach:
                        // - Start with a clean index from HEAD
                        // - Re-apply all hunks EXCEPT the one we want to unstage

                        // Reset our working index to HEAD state
                        git_index_clear(index)
                        git_index_read_tree(index, headTree)

                        // Create context to track which hunks we want to apply
                        struct ApplyContext {
                            var currentHunk: Int = 0
                            var skipHunk: Int
                        }

                        let context = ApplyContext(skipHunk: hunkIndex)
                        let contextPtr = UnsafeMutablePointer<ApplyContext>.allocate(capacity: 1)
                        contextPtr.initialize(to: context)
                        defer { contextPtr.deallocate() }

                        // Set up options for applying the diff
                        var applyOpts = git_apply_options()
                        git_apply_options_init(&applyOpts, UInt32(GIT_APPLY_OPTIONS_VERSION))

                        // Define hunk filter callback (as a global function)
                        func stageHunkCallback(hunk_data: UnsafePointer<git_diff_hunk>?, payload: UnsafeMutableRawPointer?) -> Int32 {
                            guard let payload = payload else { return 0 }

                            let contextPtr = payload.assumingMemoryBound(to: ApplyContext.self)
                            let currentHunk = contextPtr.pointee.currentHunk
                            let skipHunk = contextPtr.pointee.skipHunk

                            // Increment for next time
                            contextPtr.pointee.currentHunk += 1

                            // Return non-zero (skip) only for the target hunk
                            return currentHunk == skipHunk ? 1 : 0
                        }

                        // Set callback and payload
                        applyOpts.hunk_cb = stageHunkCallback
                        applyOpts.payload = UnsafeMutableRawPointer(contextPtr)

                        // 5. Apply the original diff to our index, skipping the hunk we want to unstage
                        if git_apply(pointer, diff, GIT_APPLY_LOCATION_INDEX, &applyOpts) == 0 {
                            // 6. Write the updated index
                            if git_index_write(index) == 0 {
                                // Success! The hunk has been unstaged
                                return
                            } else {
                                throw StageHunkError.indexWrite
                            }
                        } else {
                            // Restore the original index if apply fails
                            git_index_clear(index)

                            let entriesCount = git_index_entrycount(originalIndex)
                            for i in 0..<entriesCount {
                                if let entry = git_index_get_byindex(originalIndex, i) {
                                    git_index_add(index, entry)
                                }
                            }
                            git_index_write(index)

                            throw StageHunkError.patchApplication
                        }
                    } else {
                        throw StageHunkError.invalidHunkIndex
                    }
                } else {
                    throw StageHunkError.patchCreation
                }
            } else {
                // Clean up if diff creation failed
                free(strPtr)
                strPtrArray.deallocate()
                throw StageHunkError.diffCreation
            }
        }
    }


    // Define specific error types for better error handling
    enum StageHunkError: Error {
        case repositoryOpen
        case indexAccess
        case indexCreation
        case diffCreation
        case patchCreation
        case patchApplication
        case patchConversion
        case hunkAccess
        case indexWrite
        case headReference
        case commitLookup
        case treeAccess
        case treeRead
        case noChanges
        case invalidHunkIndex
    }
}

func hunkSelectionCallback(hunk_data: UnsafePointer<git_diff_hunk>?, payload: UnsafeMutableRawPointer?) -> Int32 {
    guard let payload else { return 0 }

    // Get the target hunk index from the payload
    let hunkIndexPtr = payload.assumingMemoryBound(to: Int.self)
    let targetHunkIndex = hunkIndexPtr.pointee

    // Get the current hunk index that's being processed
    // For this we need to use the payload to also track the current hunk count
    let contextPtr = payload.assumingMemoryBound(to: HunkContext.self)
    let currentHunkIndex = contextPtr.pointee.currentHunkIndex

    // Increment the counter for the next callback
    contextPtr.pointee.currentHunkIndex += 1

    // Return 1 (apply) only if this is the hunk we want
    return currentHunkIndex == targetHunkIndex ? 1 : 0
}

// Structure to track both the target hunk and current hunk index
struct HunkContext {
    var targetHunkIndex: Int
    var currentHunkIndex: Int
}
