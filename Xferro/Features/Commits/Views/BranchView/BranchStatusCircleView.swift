//
//  BranchStatusCircleView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct BranchStatusCircleView: View {
    let selectableStatus: any SelectableItem
    let onIsSelected: ((any SelectableItem) -> Bool)?
    let onUserTapped: (((any SelectableItem)) -> Void)?
    var body: some View {
        Circle()
            .fill(Color.accentColor.opacity(0.7))
            .overlay {
                Text("Status")
                    .font(.commitCircle)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            }
            .onTapGesture {
                onUserTapped?(selectableStatus)
            }
            .frame(width: BranchView.commitNodeSize, height: BranchView.commitNodeSize)
        if onIsSelected?(selectableStatus) ?? false {
            SelectedItemOverlay(width: BranchView.commitNodeSize, height: BranchView.commitNodeSize)
        }
    }
}
