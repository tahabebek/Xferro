//
//  String+C.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

extension String {
    func toUnsafePointer() -> UnsafePointer<UInt8>? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        let stream = OutputStream(toBuffer: buffer, capacity: data.count)
        stream.open()
        let value = data.withUnsafeBytes { $0.baseAddress?.assumingMemoryBound(to: UInt8.self) }
        guard let val = value else {
            return nil
        }
        stream.write(val, maxLength: data.count)
        stream.close()

        return UnsafePointer<UInt8>(buffer)
    }

    func toUnsafePointer() -> UnsafePointer<Int8>? {
        return UnsafePointer(strdup(self))
    }

    public init?(bytes: UnsafeRawPointer, count: Int) {
        let data = Data(bytes: bytes, count: count)
        self.init(data: data, encoding: String.Encoding.utf8)
    }

}
