//
//  PeekViewContainer.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct PeekViewContainer: View {
    @Binding var scrollToFile: String?
    @Binding var trackedDeltaInfos: [DeltaInfo]
    @Binding var untrackedDeltaInfos: [DeltaInfo]
    let head: Head

    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    ForEach($trackedDeltaInfos) { deltaInfo in
                        PeekView(deltaInfo: deltaInfo, head: head)
                    }
                }
                Section {
                    ForEach($untrackedDeltaInfos) { deltaInfo in
                        PeekView(deltaInfo: deltaInfo, head: head)
                    }
                }
            }
            .listSectionSeparator(.hidden)
            .listStyle(PlainListStyle())
            .scrollContentBackground(.hidden)
            .environment(\.defaultMinListRowHeight, 0)
            .onChange(of: scrollToFile) { _, id in
                if let id {
                    withAnimation {
                        proxy.scrollTo(id, anchor: .top)
                    }
                }
            }
        }
    }
}
