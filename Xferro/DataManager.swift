//
//  DataManager.swift
//  SwiftSpace
//
//  Created by Taha Bebek on 12/30/24.
//

import Foundation

struct DataManager {
    static let appDirPath = FileManager.urls(forDirectory: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("com.xferro.Xferro").standardized.path
    static let appDir = URL(fileURLWithPath: Self.appDirPath, isDirectory: true)    
    static let usersFileName = "xferro-users.json"


    static func save<T: Encodable>(_ object: T, filename: String) {
        try? FileManager.createDirectory(
            atURL: appDir,
            withIntermediateDirectories: true,
            attributes: nil
        )
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

            let data = try encoder.encode(object)
            let fileURL = appDir.appendingPathComponent(filename)

            try data.write(to: fileURL)
//            print("Data saved successfully to: \(fileURL)")
        } catch {
            print("Error saving data: \(error)")
        }
    }

    static func load<T: Decodable>(_ type: T.Type, filename: String) -> T? {
        let fileURL = appDir.appendingPathComponent(filename)

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let value = try decoder.decode(type, from: data)
//            print("Data successfully loaded from: \(fileURL)")
            return value
        } catch {
            print("Error loading data: \(error)")
            return nil
        }
    }

    static func delete(filename: String) {
        let fileURL = appDir.appendingPathComponent(filename)

        do {
            if FileManager.fileExists(at: fileURL.path) {
                try FileManager.removeItem(atURL: fileURL)
                return
            } else {
                return
            }
        } catch {
            return
        }
    }
}
