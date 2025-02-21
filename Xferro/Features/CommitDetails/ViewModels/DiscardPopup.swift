//
//  DiscardPopup.swift
//  Xferro
//
//  Created by Taha Bebek on 2/21/25.
//

import Observation
import SwiftUI

@Observable final class DiscardPopup {
    var isPresented: Bool = false
    @ObservationIgnored var title: String = ""
    @ObservationIgnored var onConfirm: (() -> Void)?
    @ObservationIgnored var onCancel: (() -> Void)?

    func show(
        title: String,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        isPresented = true
    }
}
