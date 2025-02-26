//
//  RepoManager.swift
//  Xferro
//
//  Created by Taha Bebek on 1/14/25.
//

import Foundation

struct RepoManager {
    func cleanGarbage(_ repository: Repository) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["gc", "--prune=now"]
        process.currentDirectoryURL = URL(fileURLWithPath: repository.workDir.path)

        // To capture output if needed
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try? process.run()
        process.waitUntilExit()

        // Check if successful
        if process.terminationStatus != 0 {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let error = NSError(domain: "GitError",
                          code: Int(process.terminationStatus),
                          userInfo: [NSLocalizedDescriptionKey: "Git GC failed: \(output)"])
            print(error)
        }
    }

    func printFolderTree(_ repository: Repository) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/tree")
        process.arguments = ["-a"]
        process.currentDirectoryURL = URL(fileURLWithPath: repository.workDir.path)

        // To capture output if needed
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try? process.run()

        let outputData = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: outputData, encoding: .utf8) {
            print(output)
        }
        
        process.waitUntilExit()

        // Check if successful
        if process.terminationStatus != 0 {
            let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            let error = NSError(domain: "GitError",
                                code: Int(process.terminationStatus),
                                userInfo: [NSLocalizedDescriptionKey: "Tree failed: \(output)"])
            print(error)
        }
    }

    func reverseLog(_ path: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.currentDirectoryURL = URL(fileURLWithPath: path)
        process.arguments = ["log", "--all", "--graph", "--decorate", "--oneline", "--simplify-by-decoration"]

        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                if process.terminationStatus != 0 {
                    print("Git command failed with status \(process.terminationStatus)")
                    print("Command output: \(output)")
                    let error = NSError(domain: "GitError",
                                        code: Int(process.terminationStatus),
                                        userInfo: [NSLocalizedDescriptionKey: "Git failed: \(output)"])
                    print(error)
                }

                let reversedOutput = output.components(separatedBy: .newlines).reversed().joined(separator: "\n")
                print(reversedOutput)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
    }

    @discardableResult
    func git(_ repository: Repository, _ args: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")

        var environment = [String: String]()
        environment["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"
        environment["HOME"] = NSHomeDirectory()
        environment["GIT_CONFIG_NOSYSTEM"] = "1"
        environment["GIT_TERMINAL_PROMPT"] = "0"
        environment["GIT_EXEC_PATH"] = "/usr/libexec/git-core"
        environment["GIT_TEMPLATE_DIR"] = "/usr/share/git-core/templates"
        // Disable all external commands/helpers
        environment["GIT_EXTERNAL_DIFF"] = "true"
        environment["GIT_PAGER"] = "cat"
        process.environment = environment

        var fullArgs = [
            "-c", "user.name=Temporary",
            "-c", "user.email=temporary@example.com",
            "-c", "core.autocrlf=false",
            "-c", "core.editor=true",
            "-c", "filter.lfs.clean=true",
            "-c", "filter.lfs.smudge=true",
            "-c", "filter.lfs.process=true",
            "-c", "filter.lfs.required=false"
        ]
        fullArgs.append(contentsOf: args)
        process.arguments = fullArgs
        process.currentDirectoryURL = URL(fileURLWithPath: repository.workDir.path)

        // To capture output if needed
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
                print(error)
                fatalError(.unhandledError)
            }
            return output
        } catch {
            print("Failed to run git: \(error)")
            fatalError(.unhandledError)
        }
    }
}
