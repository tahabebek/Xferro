//
//  PeekViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import Foundation
import Observation

@Observable final class PeekViewModel {
    var peekInfo: PeekInfo

    init(peekInfo: PeekInfo) {
        self.peekInfo = peekInfo
    }
}

