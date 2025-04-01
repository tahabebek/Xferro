//
//  DiscardAllButton.swift
//  Xferro
//
//  Created by Taha Bebek on 3/18/25.
//

import SwiftUI

struct DiscardAllButton: View {
    @Binding var hasChanges: Bool

    let title: String
    let onDiscardAll: () -> Void

    var body: some View {
        XFButton<Void,Text>(
            title: title,
            disabled: !hasChanges,
            onTap: {
                onDiscardAll()
            }
        )
    }
}
