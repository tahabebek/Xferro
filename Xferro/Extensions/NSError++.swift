//
//  NSError++.swift
//  Xferro
//
//  Created by Taha Bebek on 3/14/25.
//

import Foundation

extension NSError {
    convenience init(osStatus: OSStatus) {
        self.init(domain: NSOSStatusErrorDomain, code: Int(osStatus), userInfo: nil)
    }
}
