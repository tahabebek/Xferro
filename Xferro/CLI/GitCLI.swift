//
//  GitCLI.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//

import Foundation

enum GitCLI {
    static func gitProcess(_ repository: Repository?, _ args: [String]) -> Process {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")

        var environment = [String: String]()
        environment["PATH"] = "/usr/bin:/bin:/usr/sbin:/sbin"
        environment["HOME"] = NSHomeDirectory()
        environment["GIT_CONFIG_NOSYSTEM"] = "1"
        environment["GIT_TERMINAL_PROMPT"] = "0"
        environment["GIT_REDIRECT_STDERR"] = "2"
        environment["GIT_EXEC_PATH"] = "/usr/libexec/git-core"
        // Disable all external commands/helpers
        environment["GIT_EXTERNAL_DIFF"] = "true"
        environment["GIT_PAGER"] = "cat"
        if let sshAuthSock = ProcessInfo.processInfo.environment["SSH_AUTH_SOCK"] {
            environment["SSH_AUTH_SOCK"] = sshAuthSock
        }
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
        if let repository {
            process.currentDirectoryURL = repository.workDir
        }
        return process
    }

    @discardableResult
    static func execute(_ repository: Repository?, _ args: [String]) throws -> String {
        let process = gitProcess(repository, args)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            print("Git command failed with status \(process.terminationStatus)")
            print("Command output: \(output)")
            let error = NSError(
                domain: "GitError",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "Git failed: \(output)"]
            )
            throw error
        }
        return output
    }
    
    static func clone(
        sourcePath: String,
        destinationPath: String,
        progressHandler: @escaping (String) -> Void,
        completion: @escaping (Bool, String?) -> Void
    ) throws {
        let process = GitCLI.gitProcess(nil, ["clone", "--progress", sourcePath, destinationPath])
        
        let errorPipe = Pipe()
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        var outputData = Data()
        var errorData = Data()
        
        outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if !data.isEmpty {
                outputData.append(data)
                if let output = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        progressHandler("output pipe: \(output)")
                    }
                }
            }
        }
        
        errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
            let data = fileHandle.availableData
            if !data.isEmpty {
                errorData.append(data)
                if let error = String(data: data, encoding: .utf8) {
                    DispatchQueue.main.async {
                        // Git sends progress information to stderr, so we need to report it
                        progressHandler("progress pipe: \(error)")
                    }
                }
            }
        }
        
        process.terminationHandler = { proc in
            // Clean up handlers
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            
            // Collect any remaining data
            let remainingOutput = outputPipe.fileHandleForReading.readDataToEndOfFile()
            outputData.append(remainingOutput)
            
            let remainingError = errorPipe.fileHandleForReading.readDataToEndOfFile()
            errorData.append(remainingError)
            
            // Report any final output
            if let finalOutput = String(data: remainingOutput, encoding: .utf8), !finalOutput.isEmpty {
                DispatchQueue.main.async {
                    progressHandler(finalOutput)
                }
            }
            
            if let finalError = String(data: remainingError, encoding: .utf8), !finalError.isEmpty {
                DispatchQueue.main.async {
                    progressHandler(finalError)
                }
            }
            
            // Convert output to strings
            let outputString = String(data: outputData, encoding: .utf8) ?? ""
            let errorString = String(data: errorData, encoding: .utf8) ?? ""
            
            // Combine messages
            let combinedMessage = [outputString, errorString]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            
            // Check if clone was successful
            let success = proc.terminationStatus == 0
            
            // Complete with results
            DispatchQueue.main.async {
                completion(success, combinedMessage.isEmpty ? nil : combinedMessage)
            }
        }
        
        do {
            try process.run()
        } catch {
            completion(false, "Failed to run git: \(error)")
        }
    }

    static func getDiff(
        _ repository: Repository,
        _ args: [String],
        reverse: Bool = false,
        output: String? = nil
    ) -> Result<String, DiffError> {
        var fullArgs = ["diff", "--no-index", "-u", "--no-color", "--no-ext-diff"]
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
