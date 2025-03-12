//
//  CLI.swift
//  Xferro
//
//  Created by Taha Bebek on 3/12/25.
//

import Foundation

class CLIProcess {
    let process: Process

    init(
        executableURL: URL?,
        arguments: [String]?,
        environment: [String: String]?,
        currentDirectoryURL: URL?
    ) throws {
        self.process = Process()
        process.executableURL = executableURL
        process.arguments = arguments
        process.environment = environment ?? ProcessInfo.processInfo.environment
        process.currentDirectoryURL = currentDirectoryURL
    }

    @discardableResult
    func run() -> String {
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            if process.terminationStatus != 0 {
                print("Git command failed with status \(process.terminationStatus)")
                print("Command output: \(output)")
                let error = NSError(domain: "GitError",
                                    code: Int(process.terminationStatus),
                                    userInfo: [NSLocalizedDescriptionKey: "Git failed: \(output)"])
                fatalError(.unhandledError(error.localizedDescription))
            }
            return output
        } catch {
            fatalError(.unhandledError(error.localizedDescription))
        }
    }
}
