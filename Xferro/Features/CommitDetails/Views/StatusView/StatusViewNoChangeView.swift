//
//  StatusViewNoChangeView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/25/25.
//

import SwiftUI

struct StatusViewNoChangeView: View {
    @State var selectedRemoteForPush: Remote?
    let remotes: [Remote]
    let onTapPush: (Remote?) -> Void
    let onTapForcePushWithLease: (Remote?) -> Void
    let onGetLastSelectedRemoteIndex: (String) -> Int
    let onSetLastSelectedRemoteIndex: (Int, String) -> Void
    let onAddRemoteTapped: () -> Void
    
    var body: some View {
        VStack {
            Text("No changes.")
                .font(.paragraph1)
            HStack {
                PushButton(
                    selectedRemoteForPush: $selectedRemoteForPush,
                    remotes: remotes,
                    title: "Push",
                    pushOnly: true,
                    onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                    onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                    onAddRemoteTapped: onAddRemoteTapped,
                    onPush: onTapPush
                )
                PushButton(
                    selectedRemoteForPush: $selectedRemoteForPush,
                    remotes: remotes,
                    title: "Force Push with Lease",
                    force: true,
                    pushOnly: true,
                    onGetLastSelectedRemoteIndex: onGetLastSelectedRemoteIndex,
                    onSetLastSelectedRemoteIndex: onSetLastSelectedRemoteIndex,
                    onAddRemoteTapped: onAddRemoteTapped,
                    onForcePushWithLease: onTapForcePushWithLease
                )
            }
            .frame(height: 24)
            Spacer()
        }
    }
}
