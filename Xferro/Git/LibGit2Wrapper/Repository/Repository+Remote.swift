//
//  Repository+Remote.swift
//  SwiftGit2-OSX
//
//  Created by Whirlwind on 2019/6/17.
//  Copyright © 2019 GitHub, Inc. All rights reserved.
//

import Foundation

extension Repository: RemoteManagement {
    func allRemotes() -> Result<[Remote], NSError> {
        lock.lock()
        defer { lock.unlock() }
        let pointer = UnsafeMutablePointer<git_strarray>.allocate(capacity: 1)


        defer {
            pointer.deallocate()
        }
        let result = git_remote_list(pointer, self.pointer)

        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_remote_list"))
        }

        let strarray = pointer.pointee
        let remotes: [Result<Remote, NSError>] = strarray.map {
            if let remote = self.remote(named: $0) {
                return .success(remote)
            } else {
                return .failure(NSError(domain: "", code: 0, userInfo: nil))
            }
        }
        git_strarray_dispose(pointer)

        return remotes.aggregateResult()
    }

    func remoteNames() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        var strArray = git_strarray()
        guard git_remote_list(&strArray, pointer) == 0
        else { return [] }
        defer {
            git_strarray_free(&strArray)
        }
        return strArray.compactMap { $0 }
    }
    
    func remote(named name: String) -> Remote? {
        Remote(name: name, repository: pointer)
    }
    
    func addRemote(named name: String, url: URL) throws {
        lock.lock()
        defer { lock.unlock() }
        var remote: OpaquePointer? = nil
        let result = git_remote_create(&remote, pointer, name, url.absoluteString)

        try RepoError.throwIfGitError(result)
    }
    
    func deleteRemote(named name: String) throws {
        lock.lock()
        defer { lock.unlock() }
        let result = git_remote_delete(pointer, name)
        try RepoError.throwIfGitError(result)
    }
    
    func push(branches: [String], remote: Remote, callbacks: RemoteCallbacks, force: Bool) throws {
        lock.lock()
        defer { lock.unlock() }
        var result: Int32
        let names = branches.map { force ? "+\($0.longBranchRef)" : $0.longBranchRef }


        result = names.withGitStringArray { refspecs in
            git_remote_callbacks.withCallbacks(callbacks) { gitCallbacks in
                var mutableArray = refspecs
                var options = git_push_options.defaultOptions()

                options.callbacks = gitCallbacks
                
                options.pb_parallelism = 1
                git_remote_callbacks.Callbacks.resetAuthAttempts()

                let pushResult = git_remote_push(remote.remote, &mutableArray, &options)

                if pushResult != GIT_OK.rawValue {
                    let error = git_error_last()
                    let errorMessage = error?.pointee.message.flatMap { String(cString: $0) } ?? "Unknown error"
                }

                return pushResult
            }
        }
        try RepoError.throwIfGitError(result)
    }

    func fetch(remote: Remote, options: FetchOptions) throws {
        lock.lock()
        defer { lock.unlock() }
        var refspecs = git_strarray.init()
        var result: Int32

        result = git_remote_get_fetch_refspecs(&refspecs, remote.remote)
        guard result == GIT_OK.rawValue else {
            let err = NSError(gitError: result, pointOfFailure: "git_remote_get_fetch_refspecs")
            throw err
        }
        defer {
            git_strarray_free(&refspecs)
        }

        let message = "fetching remote \(remote.name ?? "[unknown]")"

        result = git_fetch_options.withOptions(options) {
            withUnsafePointer(to: $0) { options in
                Signpost.interval(.networkOperation) {
                    git_remote_fetch(remote.remote, &refspecs, options, message)
                }
            }
        }
        guard result == GIT_OK.rawValue else {
            let err = NSError(gitError: result, pointOfFailure: "git_remote_fetch")
            throw err
        }
    }

    public func pull(branch: Branch, remote: Remote, options: FetchOptions) throws {
        lock.lock()
        defer { lock.unlock() }
        try fetch(remote: remote, options: options)
        let remoteBranch = try remoteBranch(named: "\(remote)/\(branch)").get()
        guard let remoteBranch else {
            throw NSError(gitError: 1, pointOfFailure: "git_config_get_string", description: "Could not find the upstream branch.")
        }
        try merge(branch: remoteBranch)
    }

    // What git does: (merge.c:cmd_merge)
    // - Check for detached HEAD
    // - Look up merge config values, counting options for the target branch
    //   (merge.c:git_merge_config)
    // - Parse the specified options
    // * Action: abort
    // * Action: continue
    // - Abort if there are unmerged files in the index
    // - Abort if MERGE_HEAD already exists
    // - Abort if CHERRY_PICK_HEAD already exists
    // - resolve_undo_clear: clear out old morge resolve stuff?
    // * Handle merge onto unborn branch
    // - If required, verify signatures on merge heads
    // - Set GIT_REFLOG_ACTION env
    // - Set env GITHEAD_[sha]
    // - Decide strategies, default recursive or octopus
    // - Find merge base(s)
    // - Put ORIG_HEAD ref on head commit
    // - Die if no bases found, unless --allow-unrelated-histories
    // - If the merge head *is* the base, already up-to-date
    // * Fast-forward
    // * Try trivial merge (if not ff-only) - read_tree_trivial, merge_trivial
    // * Octopus: check if up to date
    // - ff-only fails here
    // - Stash local changes if multiple strategies will be tried
    // - For each strategy:
    //   - start clean if not first iteration
    //   - try the strategy
    //   - evaluate results; stop if there was no conflict
    // * If the last strategy had no conflicts, finalize it
    // - All strategies failed?
    // - Redo the best strategy if it wasn't the last one tried
    // - Finalize with conflicts - write MERGE_HEAD, etc

    /// Merges the given branch into the current branch.
    func merge(branch: Branch) throws {
        lock.lock()
        defer { lock.unlock() }
        do {
            try mergePreCheck()
            let head = Head.of(self)
            guard case .branch(let targetBranch, _) = head else {
                throw RepoError.detachedHead
            }

            if targetBranch.oid == branch.oid {
                return
            }

            let analysis = try analyzeMerge(from: branch)

            if analysis.contains(.upToDate) {
                return
            }
            if analysis.contains(.unborn) {
                throw RepoError.unexpected
            }
            if analysis.contains(.fastForward) {
                fastForwardMerge(branch: targetBranch, remoteBranch: branch)
                return
            }

            let branchCommit = try? object(branch.oid).get() as? Commit
            let targetCommit = try? object(targetBranch.oid).get() as? Commit

            guard let branchCommit, let targetCommit else {
                throw RepoError.unexpected
            }
            if analysis.contains(.normal) {
                try normalMerge(
                    fromBranch: branch,
                    fromCommit: branchCommit,
                    targetBranch: targetBranch,
                    targetCommit: targetCommit
                )
                return
            }
            throw RepoError.unexpected
        }
    }

    private func normalMerge(
        fromBranch: Branch,
        fromCommit: Commit,
        targetBranch: Branch,
        targetCommit: Commit
    ) throws {
        lock.lock()
        defer { lock.unlock() }
        do {
            var annotated: OpaquePointer? = try annotatedCommit(branch: fromBranch)

            defer {
                git_annotated_commit_free(annotated)
            }

            var mergeOptions = git_merge_options.defaultOptions()
            var checkoutOptions = git_checkout_options.defaultOptions()
            let index = index().mustSucceed(gitDir)

            checkoutOptions.checkout_strategy = GIT_CHECKOUT_SAFE.rawValue |
            GIT_CHECKOUT_ALLOW_CONFLICTS.rawValue
            try index.refresh()

            let result = git_merge(pointer, &annotated, 1, &mergeOptions, &checkoutOptions)

            switch git_error_code(rawValue: result) {
            case GIT_OK:
                break
            case GIT_ECONFLICT:
                throw RepoError.localConflict
            default:
                throw RepoError.gitError(result)
            }

            if index.hasConflicts {
                throw RepoError.conflict
            }
            else {
                let tree = try writeTree(git_index: index.git_index)
                _ = try commit(
                    tree: tree.oid,
                    parents: [targetCommit, fromCommit],
                    message: "Merge branch \(fromBranch.name)",
                    updatingRef: targetBranch.name
                ).get()
            }
        }
    }

    private func fastForwardMerge(branch: Branch, remoteBranch: Branch) {
        lock.lock()
        defer { lock.unlock() }
        let branchName: String = if remoteBranch.isLocal {
            remoteBranch.longName
        } else {
            remoteBranch.name
        }

        // In some cases, fast-forward merging with libgit2 can clobber unrelated
        // workspace changes, so CLI is used instead for now.
        // This actually does write, but the flag is already set
        try! GitCLI.executeGit(self, ["merge", "--ff-only", branchName])
    }

    /// The full path to the MERGE_HEAD file
    var mergeHeadPath: String {
        gitDir.path +/ "MERGE_HEAD"
    }

    /// The full path to the CHERRY_PICK_HEAD file
    var cherryPickHeadPath: String {
        gitDir.path +/ "CHERRY_PICK_HEAD"
    }

    private func mergePreCheck() throws {
        if hasConflicts().mustSucceed(gitDir) {
            throw RepoError.localConflict
        }

        if FileManager.default.fileExists(atPath: mergeHeadPath) {
            throw RepoError.mergeInProgress
        }
        if FileManager.default.fileExists(atPath: cherryPickHeadPath) {
            throw RepoError.cherryPickInProgress
        }
    }

    struct MergeAnalysis: OptionSet, Sendable
    {
        let rawValue: UInt32

        /// No merge possible
        static let none: MergeAnalysis = []
        /// Normal merge
        static let normal = MergeAnalysis(rawValue: 0b0001)
        /// Already up to date, nothing to do
        static let upToDate = MergeAnalysis(rawValue: 0b0010)
        /// Fast-forward morge: just advance the branch ref
        static let fastForward = MergeAnalysis(rawValue: 0b0100)
        /// Merge target is an unborn branch
        static let unborn = MergeAnalysis(rawValue: 0b1000)
    }

    /// Determines what sort of merge can be done from the given branch.
    /// - parameter branch: Branch to merge into the current branch.
    /// - parameter fastForward: True for fast-forward only, false for
    /// fast-forward not allowed, or nil for no preference.
    func analyzeMerge(from branch: Branch, fastForward: Bool? = nil) throws -> MergeAnalysis {
        lock.lock()
        defer { lock.unlock() }
        let preference = UnsafeMutablePointer<git_merge_preference_t>.allocate(capacity: 1)
        defer {
            preference.deallocate()
        }

        if let fastForward {
            preference.pointee = fastForward ? GIT_MERGE_PREFERENCE_FASTFORWARD_ONLY
            : GIT_MERGE_PREFERENCE_NO_FASTFORWARD
        }
        else {
            preference.pointee = GIT_MERGE_PREFERENCE_NONE
        }

        let analysis = UnsafeMutablePointer<git_merge_analysis_t>.allocate(capacity: 1)
        var annotated: OpaquePointer? = try annotatedCommit(branch: branch)

        defer {
            git_annotated_commit_free(annotated)
            analysis.deallocate()
        }

        let result = withUnsafeMutablePointer(to: &annotated) {
            git_merge_analysis(analysis, preference, pointer, $0, 1)
        }

        try RepoError.throwIfGitError(result)
        return MergeAnalysis(rawValue: analysis.pointee.rawValue)
    }

    /// Wraps `git_annotated_commit_from_ref`
    /// - parameter branch: Branch to look up the tip commit
    /// - returns: An `OpaquePointer` wrapping a `git_annotated_commit`
    func annotatedCommit(branch: Branch) throws -> OpaquePointer {
        lock.lock()
        defer { lock.unlock() }
        let branchPointer = try referenceNamed(branch.name)
        defer { git_reference_free(branchPointer) }
        return try OpaquePointer.from {
            git_annotated_commit_from_ref(&$0, pointer, branchPointer)
        }
    }

    func referenceNamed(_ name: String) throws -> OpaquePointer {
        lock.lock()
        defer { lock.unlock() }
        var pointer: OpaquePointer? = nil
        let result = git_reference_lookup(&pointer, pointer, name)
        try RepoError.throwIfGitError(result)
        return pointer!
    }

    func push(
        branches: [Branch],
        remote: Remote,
        callbacks: RemoteCallbacks
    ) throws {
        lock.lock()
        defer { lock.unlock() }
        var result: Int32
        let names = branches.map { $0.longName }

        result = names.withGitStringArray { refspecs in
            git_remote_callbacks.withCallbacks(callbacks) { gitCallbacks in
                var mutableArray = refspecs
                var options = git_push_options.defaultOptions()

                options.callbacks = gitCallbacks
                return Signpost.interval(.networkOperation) {
                    git_remote_push(remote.remote, &mutableArray, &options)
                }
            }
        }
        try RepoError.throwIfGitError(result)
    }

    @discardableResult
    public func clone(
        from source: URL,
        to destination: URL,
        branch: String,
        recurseSubmodules: Bool,
        publisher: RemoteProgressPublisher
    ) throws -> Repository? {
        try branch.withCString { cBranch in
            try git_remote_callbacks.withCallbacks(publisher.callbacks) { gitCallbacks in
                var options = git_clone_options.defaultOptions()

                options.bare = 0
                options.checkout_branch = cBranch
                options.fetch_opts.callbacks = gitCallbacks

                let gitRepo: OpaquePointer

                do {
                    gitRepo = try OpaquePointer.from {
                        git_clone(&$0, source.absoluteString, destination.path, &options)
                    }
                }
                catch let error as RepoError {
                    publisher.error(error)
                    throw error
                }
                catch let error  {
                    publisher.error(.unexpected)
                    throw error
                }

                let repo = Repository(gitRepo)
                if recurseSubmodules {
                    fatalError(.unimplemented)
//                    for sub in repo.submodules() {
//                        try sub.update(callbacks: publisher.callbacks)
                        // recurse
//                    }
                }

                publisher.finished()
                return repo
            }
        }
    }

    /// Clone the repository from a given URL.
    ///
    /// remoteURL   - The URL of the remote repository
    /// localURL    - The URL to clone the remote repository into
    /// options     - The options will be used
    ///
    /// Returns a `Result` with a `Repository` or an error.
//    class func clone(from remoteURL: URL,
//                     to localURL: URL,
//                     options: CloneOptions? = nil,
//                     recurseSubmodules: Bool? = nil) -> Result<Repository, NSError> {
//        Repository.staticLock.lock()
//        defer { staticLock.unlock() }
//        let options = options ?? CloneOptions(fetchOptions: FetchOptions(url: remoteURL.absoluteString))
//        var opt = options.toGitOptions()
//
//        var pointer: OpaquePointer? = nil
//        let remoteURLString = (remoteURL as NSURL).isFileReferenceURL() ? remoteURL.path : remoteURL.absoluteString
//        let result = localURL.withUnsafeFileSystemRepresentation { localPath in
//            git_clone(&pointer, remoteURLString, localPath, &opt)
//        }
//
//        guard result == GIT_OK.rawValue else {
//            return Result.failure(NSError(gitError: result, pointOfFailure: "git_clone"))
//        }
//
//        let repository = Repository(pointer!)
//        if recurseSubmodules != false {
//            let submoduleOptions = Submodule.UpdateOptions(fetchOptions: options.fetchOptions, checkoutOptions: options.checkoutOptions)
//            repository.eachSubmodule { (submodule) -> Int32 in
//                if recurseSubmodules == true || submodule.recurseFetch != .no {
//                    submodule.update(options: submoduleOptions, init: true, rescurse: recurseSubmodules)
//                }
//                return GIT_OK.rawValue
//            }
//        }
//        return Result.success(repository)
//    }

//    class func preProcessURL(_ url: URL) -> Result<String, NSError> {
//        Repository.staticLock.lock()
//        defer { Repository.staticLock.unlock() }
//        if (url as NSURL).isFileReferenceURL() {
//            return .success(url.path)
//        } else {
//            return Config.default(lock: staticLock).flatMap {
//                $0.insteadOf(originURL: url.absoluteString, direction: .Fetch)
//            }
//        }
//    }
//    class func lsRemote(at url: URL, callback: RemoteCallback? = nil) -> Result<[String], NSError> {
//        Repository.staticLock.lock()
//        defer { Repository.staticLock.unlock() }
//        return preProcessURL(url).flatMap { remoteURLString in
//            let opts = UnsafeMutablePointer<git_remote_create_options>.allocate(capacity: 1)
//            defer { opts.deallocate() }
//            var result = git_remote_create_options_init(opts, UInt32(GIT_REMOTE_CREATE_OPTIONS_VERSION))
//            guard result == GIT_OK.rawValue else {
//                return .failure(NSError(gitError: result, pointOfFailure: "git_remote_create_options_init"))
//            }
//
//            var remote: OpaquePointer? = nil
//            result = git_remote_create_with_opts(&remote, remoteURLString, opts)
//            guard result == GIT_OK.rawValue else {
//                return .failure(NSError(gitError: result, pointOfFailure: "git_remote_create_detached"))
//            }
//            var callback = (callback ?? RemoteCallback(url: url.absoluteString)).toGit()
//
//            result = git_remote_connect(remote, GIT_DIRECTION_FETCH, &callback, nil, nil)
//            guard result == GIT_OK.rawValue else {
//                return .failure(NSError(gitError: result, pointOfFailure: "git_remote_connect"))
//            }
//
//            var count: Int = 0
//            var headsPointer: UnsafeMutablePointer<UnsafePointer<git_remote_head>?>? = nil
//            result = git_remote_ls(&headsPointer, &count, remote)
//            guard result == GIT_OK.rawValue else {
//                return .failure(NSError(gitError: result, pointOfFailure: "git_remote_ls"))
//            }
//            var names = [String]()
//            for i in 0..<count {
//                let head = (headsPointer! + i).pointee!.pointee
//                names.append(String(cString: head.name))
//            }
//            return .success(names)
//        }
//    }
//
//    class func lsRemote(at url: URL, showBranch: Bool, showTag: Bool, callback: RemoteCallback? = nil) -> Result<[String], NSError> {
//        Repository.staticLock.lock()
//        defer { staticLock.unlock() }
//        return self.lsRemote(at: url, callback: callback).flatMap {
//            .success($0.compactMap {
//                if showBranch && $0.starts(with: String.branchPrefix) {
//                    return String($0.dropFirst(String.branchPrefix.count))
//                }
//                if showTag && $0.hasPrefix(String.tagPrefix) && !$0.hasSuffix("^{}") {
//                    return String($0.dropFirst(String.tagPrefix.count))
//                }
//                return nil
//            })
//        }
//    }
}
