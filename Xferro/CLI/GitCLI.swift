//
//  GitCLI.swift
//  Xferro
//
//  Created by Taha Bebek on 3/4/25.
//

import Foundation

enum GitCLI {
    static func gitProcess(_ repository: Repository?, _ args: [String]) throws -> Process {
        let gitExecPathProcess = Process()
        gitExecPathProcess.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        gitExecPathProcess.arguments = ["--exec-path"]
        let pipe = Pipe()
        gitExecPathProcess.standardOutput = pipe
        try gitExecPathProcess.run()
        gitExecPathProcess.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        let process = Process()
        
        if let gitExecPath = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
            // Now use this path
            var environment = ProcessInfo.processInfo.environment
            environment["PATH"] = "\(gitExecPath):/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
            // Rest of your environment setup
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
        }
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")

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
        let process = try gitProcess(repository, args)
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
        let process = try GitCLI.gitProcess(nil, ["clone", sourcePath, destinationPath, "--progress"])
        
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
                        progressHandler(output)
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
                        progressHandler(error)
                    }
                }
            }
        }
        
        process.terminationHandler = { proc in
            outputPipe.fileHandleForReading.readabilityHandler = nil
            errorPipe.fileHandleForReading.readabilityHandler = nil
            
            let remainingOutput = outputPipe.fileHandleForReading.readDataToEndOfFile()
            outputData.append(remainingOutput)
            
            let remainingError = errorPipe.fileHandleForReading.readDataToEndOfFile()
            errorData.append(remainingError)
            
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
            
            let outputString = String(data: outputData, encoding: .utf8) ?? ""
            let errorString = String(data: errorData, encoding: .utf8) ?? ""
            
            let combinedMessage = [outputString, errorString]
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            
            let success = proc.terminationStatus == 0
            
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

        do {
        let process = try gitProcess(repository, fullArgs + args)
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

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
            return .failure(.actualError(code: -1, localizedDescription: "Git diff failed \(error.localizedDescription)"))
        }
    }

    static func showHead(_ repository: Repository, _ filePath: String) -> Result<String, ShowHeadError> {
        do {
            let process = try gitProcess(repository, ["show", "HEAD:\(filePath)"])
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            
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
            return .failure(.actualError(code: -1, localizedDescription: "Git show head failed \(error.localizedDescription)"))
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
