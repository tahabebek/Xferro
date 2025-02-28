//
//  RightImageLabelStyle.swift
//  Xferro
//
//  Created by Taha Bebek on 2/27/25.
//

import SwiftUI

struct RightImageLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            configuration.icon
        }
    }
}
