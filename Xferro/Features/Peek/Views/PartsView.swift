//
//  PartsView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/9/25.
//

import SwiftUI

struct PartsView: View {
    @Binding var parts: [DiffHunkPart]
    let onDiscardPart: (DiffHunkPart) -> Void
    let onDiscardLine: (DiffLine) -> Void

    var body: some View {
        ForEach($parts) { part in
            PartView(
                part: part,
                onDiscardPart: { onDiscardPart(part.wrappedValue) },
                onDiscardLine: onDiscardLine
            )
        }
    }
}
