//
//  RepositoryActionsView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryActionsView: View {
    var body: some View {
        HStack {
            Image(systemName: "arrow.down")
                .contentShape(Rectangle())
                .hoverableButton("Pull changes from remote") {}
            Image(systemName: "arrow.up")
                .contentShape(Rectangle())
                .hoverableButton("Push changes to remote") {}
            Image(systemName: "cursorarrow.click.2")
                .contentShape(Rectangle())
                .hoverableButton("Checkout to a remote branch") {}
        }
    }
}
