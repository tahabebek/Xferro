//
//  GitCLI.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//

import Foundation

enum GitCLI {
    static func gitProcess(_ repository: Repository, _ args: [String]) -> Process {
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
        process.currentDirectoryURL = repository.workDir
        return process
    }

    @discardableResult
    static func executeGit(_ repository: Repository, _ args: [String]) -> String {
        let process = gitProcess(repository, args)
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
