//
//  PatchCLI.swift
//  Xferro
//
//  Created by Taha Bebek on 3/5/25.
//

import Foundation

enum PatchCLI {
    enum PatchOperation {
        case create
        case modify
        case delete
    }

    @discardableResult
    static func executePatch(
        diff: String,
        inputFilePath: String? = nil,
        outputFilePath: String? = nil,
        operation: PatchOperation
    ) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/patch")

        var arguments = ["-p1", "-i", "-"]
        // Disable backup files completely
        arguments.append("-V")
        arguments.append("none")
        
        if let inputPath = inputFilePath {
            arguments.append(inputPath)
        }
        if let outputPath = outputFilePath {
            arguments.append("-o")
            arguments.append(outputPath)
        }
        if case .create = operation {
            arguments.append("--forward")
        }
        process.arguments = arguments

        let diffPipe = Pipe()
        process.standardInput = diffPipe
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        let errorPipe = Pipe()
        process.standardError = errorPipe

        do {
            try process.run()
            if let data = diff.data(using: .utf8) {
                diffPipe.fileHandleForWriting.write(data)
                diffPipe.fileHandleForWriting.closeFile()
            }

            process.waitUntilExit()

            if process.terminationStatus != 0 {
                print("Patch command failed with status \(process.terminationStatus)")
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                let error = NSError(domain: "PatchError", code: Int(process.terminationStatus),
                              userInfo: [NSLocalizedDescriptionKey: errorMessage])
                print(error)
                fatalError(.unhandledError)
            }

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: outputData, encoding: .utf8) ?? ""
            print("Patch output: \(output)")
            return output
        } catch {
            print("Failed to run patch: \(error)")
            fatalError(.unhandledError)
        }
    }
}
