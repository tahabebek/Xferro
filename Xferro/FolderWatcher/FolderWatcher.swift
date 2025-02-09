import Foundation
import Darwin
import Combine

class FolderWatcher {
    let onChangeObserver: PassthroughSubject<Void, Never>

    private var lastModifiedTimes: [URL: Date] = [:]
    private var folderMonitors: [URL: DispatchSourceFileSystemObject] = [:]
    private let includingPaths: Set<String>
    private let excludingPaths: Set<String>
    private let gitIgnore: GitIgnore

    init(folder: URL, includingPaths: Set<String> = [], excludingPaths: Set<String> = [], onChangeObserver: PassthroughSubject<Void, Never>) {
        print("🚀 Initializing FolderWatcher for folder: \(folder.path)")
//        print("📋 Watching folders including: \(includingPaths.isEmpty ? "all" : includingPaths.joined(separator: ", "))")
//        print("📋 Watching folders excluding: \(excludingPaths.isEmpty ? "none" : excludingPaths.joined(separator: ", "))")

        self.includingPaths = includingPaths
        self.excludingPaths = excludingPaths
        self.gitIgnore = GitIgnore(rootPath: folder.path)
        self.onChangeObserver = onChangeObserver

        do {
            try setupRecursiveWatching(for: folder)
            print("✅ Successfully set up recursive watching")
        } catch {
            print("❌ Failed to setup recursive watching: \(error)")
        }
    }

    private func shouldWatch(url: URL) -> Bool {
        if gitIgnore.shouldIgnore(path: url.path) {
//            print("⏭️ Skipping gitignored path: \(url.lastPathComponent)")
            return false
        }

        if !includingPaths.isEmpty && !includingPaths.contains(url.path) {
//            print("⏭️ Skipping unmatched path: \(url.lastPathComponent)")
            return false
        }

        if excludingPaths.contains(url.path) {
//            print("⏭️ Skipping excluded path: \(url.lastPathComponent)")
            return false
        }
        return true
    }

    private func setupRecursiveWatching(for folderURL: URL) throws {
        guard shouldWatch(url: folderURL) else { return }

//        print("📂 Setting up recursive watching for: \(folderURL)")
        try setupFolderMonitoring(for: folderURL)
        try watchExistingFilesAndFolders(in: folderURL)
    }

    private func setupFolderMonitoring(for folderURL: URL) throws {
        if folderMonitors[folderURL] != nil {
            print("⚠️ Monitor already exists for: \(folderURL)")
            return
        }

        //        print("👀 Creating new monitor for: \(folderURL)")
        let directoryFD = open(folderURL.path, O_EVTONLY)
        if directoryFD < 0 {
            let error = String(cString: strerror(errno))
            print("❌ Failed to open directory: \(error)")
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
//            print("🔔 Directory event received for: \(folderURL.lastPathComponent)")
            onChangeObserver.send()
            checkForChanges(in: folderURL)
        }

        folderMonitor.setCancelHandler {
            print("🚫 Closing monitor for: \(folderURL)")
            close(directoryFD)
        }

        folderMonitor.resume()
        folderMonitors[folderURL] = folderMonitor
//        print("✅ Monitor successfully set up for: \(folderURL)")
    }

    private func watchExistingFilesAndFolders(in folderURL: URL) throws {
        //        print("📝 Scanning existing contents in: \(folderURL)")
        let contents = try FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey, .isDirectoryKey]
        )

        //        print("📊 Found \(contents.count) items in directory")

        for url in contents {
            // Skip if path is gitignored
            guard shouldWatch(url: url) else { continue }

            guard let resourceValues = try? url.resourceValues(forKeys: [
                .isRegularFileKey,
                .isDirectoryKey,
                .contentModificationDateKey
            ]) else {
                print("⚠️ Couldn't get resource values for: \(url)")
                continue
            }

            if resourceValues.isDirectory ?? false {
                //                print("📁 Found directory: \(url.lastPathComponent)")
                try setupRecursiveWatching(for: url)
            } else if resourceValues.isRegularFile ?? false {
                if let modificationDate = resourceValues.contentModificationDate {
                    lastModifiedTimes[url] = modificationDate
//                    print("📄 Caching modification time for file: \(url.lastPathComponent)")
                }
            }
        }
    }

    private func checkForChanges(in folderURL: URL) {
        //        print("\n🔍 Checking for changes in: \(folderURL)")
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.contentModificationDateKey, .isRegularFileKey, .isDirectoryKey]
        ) else {
            print("❌ Failed to read directory contents")
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
                print("⚠️ Couldn't get resource values for: \(url.lastPathComponent)")
                continue
            }

            if resourceValues.isDirectory ?? false {
                if folderMonitors[url] == nil {
//                    print("📁 Found new directory: \(url.lastPathComponent)")
                    try? setupRecursiveWatching(for: url)
                }
            } else if resourceValues.isRegularFile ?? false {
                if let modificationDate = resourceValues.contentModificationDate {
                    let lastModified = lastModifiedTimes[url]
                    if lastModified != modificationDate {
//                        print("📝 File modified: \(url.lastPathComponent)")
//                        print("   Previous mod time: \(String(describing: lastModified))")
//                        print("   New mod time: \(modificationDate)")
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
//            print("🗑️ Removing tracking for deleted file: \(url.lastPathComponent)")
            lastModifiedTimes.removeValue(forKey: url)
        }
    }

    deinit {
        print("♻️ Cleaning up FolderWatcher")
        folderMonitors.values.forEach { $0.cancel() }
        folderMonitors.removeAll()
    }
}
