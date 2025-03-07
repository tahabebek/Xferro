//
//  DiffCLI.swift
//  Xferro
//
//  Created by Taha Bebek on 3/5/25.
//

import Foundation

enum DiffCLI {
    static func diffProcess(_ repository: Repository, _ args: [String], reverse: Bool = false) -> Process {
        let process = Process()
        process.currentDirectoryURL = URL(fileURLWithPath: repository.workDir.path)
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")

        var fullArgs = ["diff", "-u"]
        if reverse {
            fullArgs.append("-R")
        }
        process.arguments = ["diff", "-u"] + args
        return process
    }

    @discardableResult
    static func executeDiff(_ repository: Repository, _ args: [String], reverse: Bool = false) -> String {
        let process = diffProcess(repository, args)
        // To capture output if needed
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            /*
             Exit status 0: No differences found
             Exit status 1: Differences found
             Exit status >1: Actual error occurred
             */
            if process.terminationStatus > 1 {
                print("Diff command failed with status \(process.terminationStatus)")
                print("Command output: \(output)")
                let error = NSError(domain: "DiffError",
                                    code: Int(process.terminationStatus),
                                    userInfo: [NSLocalizedDescriptionKey: "Diff failed: \(output)"])
                print(error.localizedDescription)
                fatalError(error.localizedDescription)
            }
            return output
        } catch {
            print("Failed to run diff: \(error)")
            fatalError(.unhandledError)
        }
    }
}
