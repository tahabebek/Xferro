//
//  Data.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation

extension Data
{
    func isBinary() -> Bool
    {
        withUnsafeBytes {
            (data: UnsafeRawBufferPointer) -> Bool in
            git_blob_data_is_binary(data.bindMemory(to: Int8.self).baseAddress, count) != 0
        }
    }
}
