//
//  RepositoryNavigationView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryNavigationView: View {
    @Binding var isCollapsed: Bool
    let deleteRepositoryTapped: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "xmark")
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        deleteRepositoryTapped()
                    }
                }
            Image(systemName: "chevron.down")
                .rotationEffect(Angle(degrees: !isCollapsed ? -180 : 0))
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        isCollapsed.toggle()
                    }
                }
        }
    }
}

