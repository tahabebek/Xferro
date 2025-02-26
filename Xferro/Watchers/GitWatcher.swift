//
//  GitWatcher.swift
//  Xferro
//
//  Created by Taha Bebek on 2/20/25.
//

import Combine
import Foundation

final class GitWatcher {
    static let gitDebounce = 2
    let repository: Repository

    var stream: FileEventStream! = nil
    var packedRefsWatcher: FileMonitor?
    var stashWatcher: FileMonitor?
    let queue: TaskQueue

    let headChangePublisher: PassthroughSubject<Void, Never>
    let indexChangePublisher: PassthroughSubject<Void, Never>
    let reflogChangePublisher: PassthroughSubject<Void, Never>
    let localBranchesChangePublisher: PassthroughSubject<[RefKey: Set<String>], Never>
    let remoteBranchesChangePublisher: PassthroughSubject<[RefKey: Set<String>], Never>
    let tagsChangePublisher: PassthroughSubject<[RefKey: Set<String>], Never>
    let stashChangePublisher: PassthroughSubject<Void, Never>
    
    var changeObserver: AnyCancellable?
    let mutex = NSRecursiveLock()

    private var lastIndexChangeGuarded = Date()
    var lastIndexChange: Date
    {
        get
        { mutex.withLock { lastIndexChangeGuarded } }
        set
        {
            mutex.withLock { lastIndexChangeGuarded = newValue }
            indexChangePublisher.send()
        }
    }

    var localBranchCache: [String: OID] = [:]
    var remoteBranchCache: [String: OID] = [:]
    var tagCache: [String: OID] = [:]
    var packedRefsSink, stashSink: AnyCancellable?

    init(
        repository: Repository,
        headChangePublisher: PassthroughSubject<Void, Never>,
        indexChangePublisher: PassthroughSubject<Void, Never>,
        reflogChangePublisher: PassthroughSubject<Void, Never>,
        localBranchesChangePublisher: PassthroughSubject<[RefKey: Set<String>], Never>,
        remoteBranchesChangePublisher: PassthroughSubject<[RefKey: Set<String>], Never>,
        tagsChangePublisher: PassthroughSubject<[RefKey: Set<String>], Never>,
        stashChangePublisher: PassthroughSubject<Void, Never>
    ) {
        self.repository = repository
        self.headChangePublisher = headChangePublisher
        self.indexChangePublisher = indexChangePublisher
        self.reflogChangePublisher = reflogChangePublisher
        self.localBranchesChangePublisher = localBranchesChangePublisher
        self.remoteBranchesChangePublisher = remoteBranchesChangePublisher
        self.tagsChangePublisher = tagsChangePublisher
        self.stashChangePublisher = stashChangePublisher
        self.queue = TaskQueue(id: Self.taskQueueID(path: repository.workDir.path))

        repository.references(withPrefix: "").mustSucceed().forEach { localBranchCache[$0.longName] = $0.oid }
        let objectsPath = repository.gitDir.appendingPathComponent("objects").path

        let changeSubject = PassthroughSubject<Set<String>, Never>()
        self.changeObserver = changeSubject
            .collect(.byTime(RunLoop.main, .seconds(Self.gitDebounce)))
            .sink { [weak self] batchPaths in
                guard let self else { return }
                let changedPaths = Set(batchPaths.flatMap { $0 })
                self.observeEvents(changedPaths)
            }

        let stream = FileEventStream(
            path: repository.gitDir.path,
            excludePaths: [objectsPath],
            queue: self.queue.queue,
            changePublisher: changeSubject)

        self.stream = stream
        makePackedRefsWatcher()
        makeStashWatcher()
    }

    func observeEvents(_ paths: Set<String>)
    {
        let standardizedPaths = paths.map { ($0 as NSString).standardizingPath }

        checkIndex()
        checkHead(changedPaths: standardizedPaths)
        checkRefs(changedPaths: standardizedPaths)
        checkLogs(changedPaths: standardizedPaths)
    }

    func checkIndex()
    {
        let indexPath = repository.gitDir.appendingPathComponent("index").path
        guard let indexAttributes = try? FileManager.attributesOfItem(at: indexPath),
              let newMod = indexAttributes[FileAttributeKey.modificationDate]
                as? Date
        else {
            lastIndexChange = Date.distantPast
            return
        }

        if lastIndexChange.compare(newMod) != .orderedSame {
            lastIndexChange = newMod
        }
    }

    func checkHead(changedPaths: [String])
    {
        if paths(changedPaths, includeSubpaths: ["HEAD"]) {
            headChangePublisher.send()
        }
    }

    func checkRefs(changedPaths: [String])
    {
        mutex.withLock {
            if packedRefsWatcher == nil,
               changedPaths.contains(repository.gitDir.path) {
                makePackedRefsWatcher()
            }
        }

        if paths(changedPaths, includeSubpaths: ["refs/heads"]) {
            checkLocalBranches()
        }
        if paths(changedPaths, includeSubpaths: ["refs/remotes"]) {
            checkRemoteBranches()
        }
        if paths(changedPaths, includeSubpaths: ["refs/tags"]) {
            checkTags()
        }
    }

    func checkRemoteBranches() {
        mutex.lock()
        defer { mutex.unlock() }

        var newRefCache = [String: OID]()
        repository.references(withPrefix: "refs/remotes").mustSucceed().forEach { newRefCache[$0.longName] = $0.oid }
        let newKeys = Set(newRefCache.keys)
        let oldKeys = Set(remoteBranchCache.keys)
        let addedRefs = newKeys.subtracting(oldKeys)
        let deletedRefs = oldKeys.subtracting(newKeys)
        let changedRefs = newKeys.subtracting(addedRefs).filter {
            (ref) -> Bool in
            guard let oldOID = remoteBranchCache[ref],
                  let newOID =  newRefCache[ref]
            else { return false }

            return oldOID != newOID
        }

        var refChanges = [RefKey: Set<String>]()

        if !addedRefs.isEmpty {
            refChanges[RefKey.added] = addedRefs
        }
        if !deletedRefs.isEmpty {
            refChanges[RefKey.deleted] = deletedRefs
        }
        if !changedRefs.isEmpty {
            refChanges[RefKey.changed] = Set(changedRefs)
        }

        if !refChanges.isEmpty {
            remoteBranchesChangePublisher.send(refChanges)
        }

        remoteBranchCache = newRefCache
    }
    func checkTags() {
        mutex.lock()
        defer { mutex.unlock() }

        var newRefCache = [String: OID]()
        repository.references(withPrefix: "refs/tags").mustSucceed().forEach { newRefCache[$0.longName] = $0.oid }
        let newKeys = Set(newRefCache.keys)
        let oldKeys = Set(tagCache.keys)
        let addedRefs = newKeys.subtracting(oldKeys)
        let deletedRefs = oldKeys.subtracting(newKeys)
        let changedRefs = newKeys.subtracting(addedRefs).filter {
            (ref) -> Bool in
            guard let oldOID = tagCache[ref],
                  let newOID =  newRefCache[ref]
            else { return false }

            return oldOID != newOID
        }

        var refChanges = [RefKey: Set<String>]()

        if !addedRefs.isEmpty {
            refChanges[RefKey.added] = addedRefs
        }
        if !deletedRefs.isEmpty {
            refChanges[RefKey.deleted] = deletedRefs
        }
        if !changedRefs.isEmpty {
            refChanges[RefKey.changed] = Set(changedRefs)
        }

        if !refChanges.isEmpty {
            tagsChangePublisher.send(refChanges)
        }

        tagCache = newRefCache
    }
    func checkLocalBranches()
    {
        mutex.lock()
        defer { mutex.unlock() }

        var newRefCache = [String: OID]()
        repository.references(withPrefix: "refs/heads").mustSucceed().forEach { newRefCache[$0.longName] = $0.oid }
        let newKeys = Set(newRefCache.keys)
        let oldKeys = Set(localBranchCache.keys)
        let addedRefs = newKeys.subtracting(oldKeys)
        let deletedRefs = oldKeys.subtracting(newKeys)
        let changedRefs = newKeys.subtracting(addedRefs).filter {
            (ref) -> Bool in
            guard let oldOID = localBranchCache[ref],
                  let newOID =  newRefCache[ref]
            else { return false }

            return oldOID != newOID
        }

        var refChanges = [RefKey: Set<String>]()

        if !addedRefs.isEmpty {
            refChanges[RefKey.added] = addedRefs
        }
        if !deletedRefs.isEmpty {
            refChanges[RefKey.deleted] = deletedRefs
        }
        if !changedRefs.isEmpty {
            refChanges[RefKey.changed] = Set(changedRefs)
        }

        if !refChanges.isEmpty {
            localBranchesChangePublisher.send(refChanges)
        }

        localBranchCache = newRefCache
    }

    func makePackedRefsWatcher()
    {
        let watcher = FileMonitor(path: repository.gitDir.path +/ "packed-refs")

        if let watcher {
            mutex.withLock { packedRefsWatcher = watcher }
            packedRefsSink = watcher.eventPublisher.sink {
                [weak self] (_, _) in
                self?.checkLocalBranches()
                self?.checkRemoteBranches()
                self?.checkRemoteBranches()
            }
        }
    }

    func makeStashWatcher()
    {
        let path = repository.gitDir.path +/ "logs/refs/stash"
        guard let watcher = FileMonitor(path: path)
        else { return }

        stashWatcher = watcher
        stashSink = watcher.eventPublisher.sink {
            [weak self] (_, _) in
            self?.stashChangePublisher.send()
        }
    }

    func checkLogs(changedPaths: [String])
    {
        if paths(changedPaths, includeSubpaths: ["logs/refs"]) {
            reflogChangePublisher.send()
        }
    }

    func paths(_ paths: [String], includeSubpaths subpaths: [String]) -> Bool
    {
        for path in paths {
            for subpath in subpaths {
                if path.hasSuffix(subpath) ||
                    URL(string: path)!.deletingLastPathComponent().path.hasSuffix(subpath) {
                    return true
                }
            }
        }
        return false
    }

    enum RefKey: Hashable
    {
        case added
        case deleted
        case changed
    }

    static func taskQueueID(path: String) -> String
    {
        let identifier = Bundle.main.bundleIdentifier ?? "com.xferro.xferro.gitwatcher"

        return "\(identifier).\(path)"
    }

    deinit {
        stashSink?.cancel()
        packedRefsSink?.cancel()
        changeObserver?.cancel()
    }
}


