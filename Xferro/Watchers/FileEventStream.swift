//
//  FileEventStream.swift
//  Xferro
//
//  Created by Taha Bebek on 2/20/25.
//

import Combine
import Foundation

public class FileEventStream
{
    var stream: FSEventStreamRef!
    let changePublisher: PassthroughSubject<Set<String>, Never>
    private let debounceInterval: TimeInterval = 0.1

    static let rescanFlags =
    UInt32(kFSEventStreamEventFlagMustScanSubDirs) |
    UInt32(kFSEventStreamEventFlagUserDropped) |
    UInt32(kFSEventStreamEventFlagKernelDropped)

    init(
        path: String,
        excludePaths: [String] = [],
        gitignoreLines: [String] = [],
        workDir: URL? = nil,
        queue: DispatchQueue,
        changePublisher: PassthroughSubject<Set<String>, Never>
    ) {
        var excludePaths = Set(excludePaths.map { (path: String) -> String in
            let absolutePath = (path as NSString).standardizingPath
            return (absolutePath as NSString).expandingTildeInPath
        })
        self.changePublisher = changePublisher
        let contents = gitignoreLines.joined(separator: "\n")
        if let workDir, gitignoreLines.isNotEmpty {
            gitignoreLines.forEach { line in
                if let first = line.first, (first == "~" || first == "/" || first == "." || first.isLetter) {
                    if workDir.appendingPathComponent(line).isDirectory {
                        if contents.firstRange(of: "!\(line)") == nil {
                            excludePaths.insert(line)
                        }
                    }
                }
            }
        }
        self.setupStream(paths: [path], excludePaths: excludePaths, queue: queue)
    }

    private func setupStream(paths: [String], excludePaths: Set<String>, queue: DispatchQueue) {
        let unsafeSelf = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        var context = FSEventStreamContext(
            version: 0,
            info: unsafeSelf,
            retain: nil,
            release: nil,
            copyDescription: nil
        )

        let callback: FSEventStreamCallback = { (streamRef, info, numEvents, eventPaths, eventFlags, _) in
            guard let info else { return }
            let monitor = Unmanaged<FileEventStream>.fromOpaque(info).takeUnretainedValue()
            monitor.handleEvents(
                numEvents: numEvents,
                paths: unsafeBitCast(eventPaths, to: NSArray.self) as? [String] ?? [],
                flags: eventFlags
            )
        }

        self.stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            callback,
            &context,
            paths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            debounceInterval, // 100ms latency
            UInt32(kFSEventStreamCreateFlagUseCFTypes |
                   kFSEventStreamCreateFlagNoDefer |
                   kFSEventStreamCreateFlagFileEvents)
        )

        // Set exclusion paths if any
        if !excludePaths.isEmpty {
            FSEventStreamSetExclusionPaths(stream, Array(excludePaths) as CFArray)
        }

        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    private func handleEvents(numEvents: Int, paths: [String], flags: UnsafePointer<FSEventStreamEventFlags>) {
        for index in 0..<numEvents
        where (flags[index] & FileEventStream.rescanFlags) != 0 {
            changePublisher.send([]) // Empty array indicates need to rescan
            return
        }
        changePublisher.send(Set(paths))
    }

    deinit
    {
        print("Deinit FileEventStream")
        if stream != nil {
            stop()
        }
    }

    func stop()
    {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }
}
