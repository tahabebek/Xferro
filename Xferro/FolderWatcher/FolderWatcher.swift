import Foundation
import Darwin
import Combine

class FolderWatcher {
    let debugEnabled: Bool
    let onChangeObserver: PassthroughSubject<Void, Never>

    private var lastModifiedTimes: [URL: Date] = [:]
    private var folderMonitors: [URL: DispatchSourceFileSystemObject] = [:]
    private let includingPaths: Set<String>
    private let excludingPaths: Set<String>
    private let gitIgnore: GitIgnore

    init(
        folder: URL,
        includingPaths: Set<String> = [],
        excludingPaths: Set<String> = [],
        onChangeObserver: PassthroughSubject<Void, Never>,
        debugEnabled: Bool = false
    ) {
        self.includingPaths = includingPaths
        self.excludingPaths = excludingPaths
        self.gitIgnore = GitIgnore(rootPath: folder.path)
        self.onChangeObserver = onChangeObserver
        self.debugEnabled = debugEnabled

        fwprint("🚀 Initializing FolderWatcher for folder: \(folder.path)")
        fwprint("📋 Watching folders including: \(includingPaths.isEmpty ? "all" : includingPaths.joined(separator: ", "))")
        fwprint("📋 Watching folders excluding: \(excludingPaths.isEmpty ? "none" : excludingPaths.joined(separator: ", "))")
        do {
            try setupRecursiveWatching(for: folder)
            fwprint("✅ Successfully set up recursive watching")
        } catch {
            fwprint("❌ Failed to setup recursive watching: \(error)")
        }
    }

    private func shouldWatch(url: URL) -> Bool {
        if gitIgnore.shouldIgnore(path: url.path) {
            fwprint("⏭️ Skipping gitignored path: \(url.lastPathComponent)")
            return false
        }

        if !includingPaths.isEmpty && !includingPaths.contains(url.path) {
            fwprint("⏭️ Skipping unmatched path: \(url.lastPathComponent)")
            return false
        }

        if excludingPaths.contains(url.path) {
            fwprint("⏭️ Skipping excluded path: \(url.lastPathComponent)")
            return false
        }
        return true
    }

    private func setupRecursiveWatching(for folderURL: URL) throws {
        guard shouldWatch(url: folderURL) else { return }

        fwprint("📂 Setting up recursive watching for: \(folderURL)")
        try setupFolderMonitoring(for: folderURL)
        try watchExistingFilesAndFolders(in: folderURL)
    }

    private func setupFolderMonitoring(for folderURL: URL) throws {
        if folderMonitors[folderURL] != nil {
            fwprint("⚠️ Monitor already exists for: \(folderURL)")
            return
        }

        fwprint("👀 Creating new monitor for: \(folderURL)")
        let directoryFD = open(folderURL.path, O_EVTONLY)
        if directoryFD < 0 {
            let error = String(cString: strerror(errno))
            fwprint("❌ Failed to open directory: \(error)")
            throw NSError(domain: "FolderWatcher",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to open directory: \(error)"])
        }

        let folderMonitor = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: directoryFD,
            eventMask: [.write, .link],
            queue: DispatchQueue.main
        )

        folderMonitor.setEventHandler { [weak self] in
            guard let self else { return }
            fwprint("🔔 Directory event received for: \(folderURL.lastPathComponent)")
            onChangeObserver.send()
            checkForChanges(in: folderURL)
        }

        folderMonitor.setCancelHandler { [weak self] in
            guard let self else { return }
            fwprint("🚫 Closing monitor for: \(folderURL)")
            close(directoryFD)
        }

        folderMonitor.resume()
        folderMonitors[folderURL] = folderMonitor
        fwprint("✅ Monitor successfully set up for: \(folderURL)")
    }

    private func watchExistingFilesAndFolders(in folderURL: URL) throws {
        fwprint("📝 Scanning existing contents in: \(folderURL)")
        let contents = try FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey, .isDirectoryKey]
        )

        fwprint("📊 Found \(contents.count) items in directory")

        for url in contents {
            // Skip if path is gitignored
            guard shouldWatch(url: url) else { continue }

            guard let resourceValues = try? url.resourceValues(forKeys: [
                .isRegularFileKey,
                .isDirectoryKey,
                .contentModificationDateKey
            ]) else {
                fwprint("⚠️ Couldn't get resource values for: \(url)")
                continue
            }

            if resourceValues.isDirectory ?? false {
                fwprint("📁 Found directory: \(url.lastPathComponent)")
                try setupRecursiveWatching(for: url)
            } else if resourceValues.isRegularFile ?? false {
                if let modificationDate = resourceValues.contentModificationDate {
                    lastModifiedTimes[url] = modificationDate
                    fwprint("📄 Caching modification time for file: \(url.lastPathComponent)")
                }
            }
        }
    }

    private func checkForChanges(in folderURL: URL) {
        fwprint("\n🔍 Checking for changes in: \(folderURL)")
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey, .isDirectoryKey]
        ) else {
            fwprint("❌ Failed to read directory contents")
            return
        }

        for url in contents {
            // Skip if path is gitignored
            guard shouldWatch(url: url) else { continue }

            guard let resourceValues = try? url.resourceValues(forKeys: [
                .contentModificationDateKey,
                .isRegularFileKey,
                .isDirectoryKey
            ]) else {
                fwprint("⚠️ Couldn't get resource values for: \(url.lastPathComponent)")
                continue
            }

            if resourceValues.isDirectory ?? false {
                if folderMonitors[url] == nil {
                    fwprint("📁 Found new directory: \(url.lastPathComponent)")
                    try? setupRecursiveWatching(for: url)
                }
            } else if resourceValues.isRegularFile ?? false {
                if let modificationDate = resourceValues.contentModificationDate {
                    let lastModified = lastModifiedTimes[url]
                    if lastModified != modificationDate {
                        fwprint("📝 File modified: \(url.lastPathComponent)")
                        fwprint("   Previous mod time: \(String(describing: lastModified))")
                        fwprint("   New mod time: \(modificationDate)")
                        lastModifiedTimes[url] = modificationDate
                    }
                }
            }
        }

        // Clean up removed files only for the current directory
        let watchedPathsInCurrentDir = Set(lastModifiedTimes.keys.filter {
            // Get parent directory of the file
            let parent = (($0.path as NSString).deletingLastPathComponent as NSString).standardizingPath
            // Check if it matches the current directory
            return parent == (folderURL.path as NSString).standardizingPath
        })

        let removedURLs = watchedPathsInCurrentDir.subtracting(contents)

        for url in removedURLs {
            fwprint("🗑️ Removing tracking for deleted file: \(url.lastPathComponent)")
            lastModifiedTimes.removeValue(forKey: url)
        }
    }

    deinit {
        fwprint("♻️ Cleaning up FolderWatcher")
        folderMonitors.values.forEach { $0.cancel() }
        folderMonitors.removeAll()
    }

    func fwprint(_ str: String) {
        if debugEnabled {
            print(str)
        }
    }
}
