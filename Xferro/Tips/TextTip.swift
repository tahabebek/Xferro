//
//  TextTip.swift
//  Xferro
//
//  Created by Taha Bebek on 2/13/25.
//

import TipKit

struct CollapseRepositoryTip: Tip {
    var title: Text { Text("Collapse Repository") }
    var message: Text? = nil
    var imageable: Image? = nil
}
