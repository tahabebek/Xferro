//
//  String+C.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

extension String {
    func toUnsafePointer() -> UnsafePointer<UInt8>? {
        guard let data = self.data(using: .utf8) else { return nil }
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        let stream = OutputStream(toBuffer: buffer, capacity: data.count)
        stream.open()
        let value = data.withUnsafeBytes { $0.baseAddress?.assumingMemoryBound(to: UInt8.self) }
        guard let value else { return nil }
        stream.write(value, maxLength: data.count)
        stream.close()
        return UnsafePointer<UInt8>(buffer)
    }

    func toUnsafePointer() -> UnsafePointer<Int8>? {
        UnsafePointer(strdup(self))
    }

    init?(bytes: UnsafeRawPointer, count: Int) {
        let data = Data(bytes: bytes, count: count)
        self.init(data: data, encoding: String.Encoding.utf8)
    }

    /// Creates a string with a copy of the buffer's contents.
    init?(gitBuffer: git_buf) {
        self.init(cString: gitBuffer.ptr, encoding: .utf8)
    }

    /// Calls `action` with a string pointing to the given buffer. If the string
    /// could not be constructed then `nil` is passed.
    static func withGitBuffer<T>(_ buffer: git_buf, action: (String?) throws -> T) rethrows -> T
    {
        let nsString = NSString(
            bytesNoCopy: buffer.ptr,
            length: strnlen(buffer.ptr, buffer.size),
            encoding: NSUTF8StringEncoding,
            freeWhenDone: false
        )

        return try action(nsString as String?)
    }

    /// Normalizes whitespace and optionally strips comment lines.
    func prettifiedMessage(stripComments: Bool) -> String {
        let commentCharASCII = Int8(Character("#").asciiValue!)
        let gitBuffer = GitBuffer(size: 0)
        let result = git_message_prettify(&gitBuffer.buffer, self,
                                          stripComments ? 1 : 0, commentCharASCII)
        guard result == 0 else { return self }
        return String(gitBuffer: gitBuffer.buffer) ?? self
    }
}
