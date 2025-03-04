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

     In stageSelectedLines:

     We use git diff without --cached to get the unstaged changes
     We use git apply --cached to apply the selected lines to the index (staging them)

     In unstageSelectedLines:

     We use git diff --cached to get the staged changes
     We use git apply --cached --reverse to unapply the selected lines from the index (unstaging them)

     The --cached flag is essential for making sure these operations affect the staging area (index) rather than your working files. This allows you to stage/unstage changes without modifying the actual content of your files.

     The trailing dash (-) in the command git apply --cached - is a special character that tells Git to read the patch content from standard input (stdin) rather than from a file.
     */
    // Define a diff line type to identify addition vs deletion
    enum StageDiffLineType {
        case addition  // + line
        case deletion  // - line
        case context   // space line
    }
    
    // Structure to represent a line selection with its type
    struct StageDiffLine {
        let lineNumber: Int
        let type: DiffLineType
    }
    
    func stageSelectedLines(filePath: String, selectedLines: [StageDiffLine]) async throws {
        print("Staging selected lines: \(selectedLines.map { "line \($0.lineNumber) (\($0.type))" })")
        
        // Get the diff for the file
        let diffOutput = GitCLI.executeGit(self, ["diff", "--no-color", "--no-ext-diff", filePath])
        
        if diffOutput.isEmpty {
            print("No unstaged changes found in \(filePath)")
            return
        }
        
        // Create a temporary patch file with just the desired changed line
        let tempPatchFile = DataManager.appDir.appendingPathComponent("temp_patch_\(UUID().uuidString)")
        
        // Parse the diff to find the exact line position
        let diffLines = diffOutput.split(separator: "\n").map(String.init)
        
        // Variables to keep track of current line numbers and hunk context
        var currentLineNumber = 0
        var oldStart = 0
        var newStart = 0
        var inHunk = false
        var targetLinePosition = -1
        var selectedLineContent = ""
        var contextLineBefore = ""
        var contextLineAfter = ""
        var fileHeader = [String]()
        var targetHunkLines = [String]()
        
        for (index, line) in diffLines.enumerated() {
            if line.starts(with: "diff ") || line.starts(with: "index ") || 
               line.starts(with: "--- ") || line.starts(with: "+++ ") {
                // Collect file header information
                fileHeader.append(line)
            } else if line.starts(with: "@@ ") {
                // Parse hunk header
                if let match = line.range(of: #"@@ -(\d+),(\d+) \+(\d+),(\d+) @@"#, options: .regularExpression) {
                    let parts = line[match].components(separatedBy: CharacterSet(charactersIn: "-+, @"))
                                          .filter { !$0.isEmpty }
                    
                    if parts.count >= 4 {
                        oldStart = Int(parts[0]) ?? 0
                        newStart = Int(parts[2]) ?? 0

                        // Reset line tracking for this hunk
                        currentLineNumber = newStart - 1  // Will be incremented with the first context/add line
                        inHunk = true
                        
                        // Start a new target hunk if containing selected lines
                        targetHunkLines = [line]
                    }
                }
            } else if inHunk {
                if line.starts(with: " ") {
                    // Context line
                    currentLineNumber += 1
                    targetHunkLines.append(line)
                    
                    // Check if this line is a context line for our selected lines
                    for selected in selectedLines {
                        if currentLineNumber + 1 == selected.lineNumber {
                            contextLineBefore = line
                            print("Found context line before selected line \(selected.lineNumber): \(line)")
                        }
                        else if currentLineNumber - 1 == selected.lineNumber {
                            contextLineAfter = line
                            print("Found context line after selected line \(selected.lineNumber): \(line)")
                        }
                    }
                } else if line.starts(with: "+") {
                    // Added line
                    currentLineNumber += 1
                    targetHunkLines.append(line)
                    
                    // Check if this is our selected line - using new DiffLine type
                    // Look for a line with this number and type 'addition'
                    if selectedLines.contains(where: { $0.lineNumber == currentLineNumber && $0.type == .addition }) {
                        targetLinePosition = targetHunkLines.count - 1
                        selectedLineContent = line
                        print("Found selected ADDITION line at position \(targetLinePosition): \(line)")
                    }
                } else if line.starts(with: "-") {
                    // Removed line (don't increment currentLineNumber)
                    targetHunkLines.append(line)
                    
                            // For removed lines, we need to properly track old file line numbers
                    // Calculate the line number in the original file
                    var oldLineNumber = oldStart
                    if targetHunkLines.count > 1 {
                        // Count context and deletion lines up to current position (excluding current line)
                        var contextAndDeletionCount = 0
                        for i in 1..<(targetHunkLines.count-1) { // Skip header and exclude current line
                            let prevLine = targetHunkLines[i]
                            if prevLine.starts(with: " ") || prevLine.starts(with: "-") {
                                contextAndDeletionCount += 1
                            }
                        }
                        oldLineNumber = oldStart + contextAndDeletionCount
                    }
                    // Check if this is our selected line with 'deletion' type
                    if selectedLines.contains(where: { $0.lineNumber == oldLineNumber && $0.type == .deletion }) {
                        targetLinePosition = targetHunkLines.count - 1
                        selectedLineContent = line
                        print("Found selected DELETION line \(oldLineNumber) at position \(targetLinePosition): \(line)")
                    }
                }
            }
        }
        
        // If we found our target line, create a minimal patch with just that change
        if targetLinePosition >= 0 {
            print("Creating patch for line at position \(targetLinePosition): \(selectedLineContent)")
            
            // Build a minimal patch with the file headers and just the selected change with necessary context
            var patchContent = fileHeader.joined(separator: "\n") + "\n"
            
            // For correct line numbers, we need to calculate the exact position where the selected line
            // should be applied, taking into account the context lines
            var effectiveOldStart = 0
            var effectiveNewStart = 0
            
            if selectedLineContent.starts(with: "-") {
                // For removed lines, we need to track where in the file this line was
                // We need to count all the context and removed lines up to our target position
                var oldLineOffset = 0
                var targetPos = 0
                
                // First find the position of our line in the targetHunkLines array
                if let linePos = targetHunkLines.firstIndex(of: selectedLineContent) {
                    targetPos = linePos
                    
                    // Now count all the lines that affect old file line numbers
                    for i in 1..<targetPos {
                        let line = targetHunkLines[i]
                        if line.starts(with: " ") || line.starts(with: "-") {
                            oldLineOffset += 1
                        }
                    }
                }
                
                // Calculate the effective start positions
                effectiveOldStart = oldStart + oldLineOffset
                effectiveNewStart = effectiveOldStart
                
                print("Deletion at oldStart: \(effectiveOldStart), offset: \(oldLineOffset)")
            } else if selectedLineContent.starts(with: "+") {
                // For added lines, we use the new file line number
                // Find the current new file line number
                let linePosition = targetHunkLines.firstIndex(of: selectedLineContent) ?? 0
                
                // Count context and add lines before this position to get correct offset
                var contextAndAddCount = 0
                if linePosition > 1 {  // Make sure we have valid range
                    for i in 1..<linePosition {
                        let line = targetHunkLines[i]
                        if line.starts(with: " ") || line.starts(with: "+") {
                            contextAndAddCount += 1
                        }
                    }
                }
                
                effectiveNewStart = newStart + contextAndAddCount
                effectiveOldStart = effectiveNewStart // Same for old start
                
                print("Addition at newStart: \(effectiveNewStart)")
            }
            
            // Create a minimal hunk with just our change
            var minimalHunk = [String]()
            
            // Calculate the number of context lines we have
            let beforeLineCount = contextLineBefore.isEmpty ? 0 : 1
            let afterLineCount = contextLineAfter.isEmpty ? 0 : 1
            let contextLineCount = beforeLineCount + afterLineCount
            
            // Select the correct hunk header format based on line type
            if selectedLineContent.starts(with: "-") {
                // For a deletion, we need to tell git that we're removing a line
                let oldLineCount = 1 + contextLineCount  // Deleted line + context lines
                let newLineCount = contextLineCount      // Just context lines in new version
                
                minimalHunk.append("@@ -\(effectiveOldStart),\(oldLineCount) +\(effectiveNewStart),\(newLineCount) @@")
                print("Using deletion header: @@ -\(effectiveOldStart),\(oldLineCount) +\(effectiveNewStart),\(newLineCount) @@")
            } else if selectedLineContent.starts(with: "+") {
                // For an addition, we're adding a line that doesn't exist in the old file
                let oldLineCount = contextLineCount      // Just context lines in old version
                let newLineCount = 1 + contextLineCount  // Added line + context lines
                
                minimalHunk.append("@@ -\(effectiveOldStart),\(oldLineCount) +\(effectiveNewStart),\(newLineCount) @@")
                print("Using addition header: @@ -\(effectiveOldStart),\(oldLineCount) +\(effectiveNewStart),\(newLineCount) @@")
            }
            
            // We need at least one context line for git apply to work properly
            if !contextLineBefore.isEmpty {
                minimalHunk.append(contextLineBefore)
            }
            
            minimalHunk.append(selectedLineContent)
            
            if !contextLineAfter.isEmpty {
                minimalHunk.append(contextLineAfter)
            }
            
            // Ensure we end the patch with a newline to avoid corrupt patch errors
            patchContent += minimalHunk.joined(separator: "\n") + "\n"
            
            print("Generated minimal patch:\n\(patchContent)")
            
            // Write the patch to a temporary file
            do {
                try patchContent.write(to: tempPatchFile, atomically: true, encoding: .utf8)
                
                // Apply the patch to the index
                GitCLI.executeGit(self, ["apply", "--cached", tempPatchFile.path])
                
                // Clean up
                try FileManager.default.removeItem(at: tempPatchFile)
            } catch {
                // Clean up on error
                try? FileManager.default.removeItem(at: tempPatchFile)
                throw error
            }
        } else {
            print("Selected line \(selectedLines) not found in diff")
            throw NSError(domain: "GitError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Selected line not found in changes"])
        }
    }

    func unstageSelectedLines(filePath: String, selectedLines: [StageDiffLine]) async throws {
        print("Unstaging selected lines: \(selectedLines.map { "line \($0.lineNumber) (\($0.type))" })")
        
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
