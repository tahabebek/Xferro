//
//  WipCommitActionButtonsView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/17/25.
//

import SwiftUI

struct WipCommitActionButtonsView: View {
    enum BoxAction: String, CaseIterable, Identifiable, Equatable {
        var id: String { rawValue }
        case doSomething = "Do something"
    }

    @State private var boxActions: [BoxAction] = BoxAction.allCases

    let onTap: (BoxAction) -> Void

    var body: some View {
        ForEach(boxActions) { boxAction in
            XFerroButton<Void>(
                title: boxAction.rawValue,
                isProminent: true,
                onTap: { onTap(boxAction) })
        }
        .animation(.default, value: boxActions)
    }
}

