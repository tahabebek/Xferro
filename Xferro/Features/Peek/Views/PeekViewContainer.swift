//
//  PeekViewContainer.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct PeekViewContainer: View {
    let viewModel: StatusViewModel
    @Binding var scrollToFile: String?
    
    var body: some View {
        ScrollViewReader { proxy in
            List {
                Section {
                    ForEach(viewModel.stagedDeltaInfos) { deltaInfo in
                        PeekView(viewModel: viewModel, deltaInfo: deltaInfo)
                    }
                }
                Section {
                    ForEach(viewModel.unstagedDeltaInfos) { deltaInfo in
                        PeekView(viewModel: viewModel, deltaInfo: deltaInfo)
                    }
                }
                Section {
                    ForEach(viewModel.untrackedDeltaInfos) { deltaInfo in
                        PeekView(viewModel: viewModel, deltaInfo: deltaInfo)
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
