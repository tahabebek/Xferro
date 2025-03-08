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

    static func getDiff(
        _ repository: Repository,
        _ args: [String],
        reverse: Bool = false,
        output: String? = nil
    ) -> Result<String, DiffError> {
        var fullArgs = ["diff", "-u", "--no-color", "--no-ext-diff"]
        if reverse {
            fullArgs.append("-R")
        }

        let process = gitProcess(repository, fullArgs + args)
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
            switch process.terminationStatus {
            case 0:
                return .failure(.noDifferencesFound)
            case 1:
                // This means file exists on disk, but not in 'HEAD'
                return .success(output)
            default:
                print("Git command failed with status \(process.terminationStatus)")
                print("Command output: \(output)")
                return .failure(.actualError(code: Int(process.terminationStatus), localizedDescription: "Git diff failed \(output)"))
            }
        } catch {
            print("Failed to run diff: \(error)")
            return .failure(.actualError(code: Int(process.terminationStatus), localizedDescription: "Git diff failed \(error.localizedDescription)"))
        }
    }

    static func showHead(_ repository: Repository, _ filePath: String) -> Result<String, ShowHeadError> {
        let process = gitProcess(repository, ["show", "HEAD:\(filePath)"])

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            switch process.terminationStatus {
            case 0:
                return .success(output)
            case 128:
                // This means file exists on disk, but not in 'HEAD'
                return .failure(.fileNotInHead)
            default:
                print("Git command failed with status \(process.terminationStatus)")
                print("Command output: \(output)")
                return .failure(.actualError(code: Int(process.terminationStatus), localizedDescription: "Git show head failed \(output)"))
            }
        } catch {
            print("Failed to run git: \(error)")
            return .failure(.actualError(code: Int(process.terminationStatus), localizedDescription: "Git show head failed \(error.localizedDescription)"))
        }
    }

    enum ShowHeadError: Error {
        case fileNotInHead
        case actualError(code: Int, localizedDescription: String)
    }

    enum DiffError: Error {
        case noDifferencesFound
        case actualError(code: Int, localizedDescription: String)
    }
}
