//
//  DataManager.swift
//  SwiftSpace
//
//  Created by Taha Bebek on 12/30/24.
//

import Foundation

struct DataManager {
    static let appDirPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("com.xferro.Xferro").standardized.path
    static let appDir = URL(fileURLWithPath: Self.appDirPath, isDirectory: true)    
    static let usersFileName = "xferro-users.json"


    static func save<T: Encodable>(_ object: T, filename: String) {
        try? FileManager.default.createDirectory(
            at: appDir,
            withIntermediateDirectories: true,
            attributes: nil
        )
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(object)
            let fileURL = appDir.appendingPathComponent(filename)

            try data.write(to: fileURL)
            print("Data saved successfully to: \(fileURL)")
        } catch {
            print("Error saving data: \(error)")
        }
    }

    static func load<T: Decodable>(_ type: T.Type, filename: String) -> T? {
        let fileURL = appDir.appendingPathComponent(filename)

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            return try decoder.decode(type, from: data)
        } catch {
            print("Error loading data: \(error)")
            return nil
        }
    }

    static func delete(filename: String) {
        let fileURL = appDir.appendingPathComponent(filename)

        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                return
            } else {
                return
            }
        } catch {
            return
        }
    }
}
