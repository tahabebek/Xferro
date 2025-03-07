//
//  PatchCLI.swift
//  Xferro
//
//  Created by Taha Bebek on 3/5/25.
//

import Foundation

enum PatchCLI {
    static func patchProcess(_ repository: Repository, _ args: [String]) -> Process {
        let process = Process()
        var environment = [String: String]()

        process.environment = environment
        process.arguments = ["patch"] + args
        process.currentDirectoryURL = repository.workDir
        return process
    }

    @discardableResult
    static func executeDiff(_ repository: Repository, _ args: [String]) -> String {
        let process = patchProcess(repository, args)
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
                print("Patch command failed with status \(process.terminationStatus)")
                print("Command output: \(output)")
                let error = NSError(domain: "PatchError",
                                    code: Int(process.terminationStatus),
                                    userInfo: [NSLocalizedDescriptionKey: "Patch failed: \(output)"])
                print(error)
                fatalError(.unhandledError)
            }
            return output
        } catch {
            print("Failed to run patch: \(error)")
            fatalError(.unhandledError)
        }
    }
}
