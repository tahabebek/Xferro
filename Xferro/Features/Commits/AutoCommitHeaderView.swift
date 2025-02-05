//
//  AutoCommitHeaderView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/5/25.
//

import SwiftUI

struct AutoCommitHeaderView: View {
    @State var autoCommitEnabled = false
    var body: some View {
        HStack {
            Text("WIP Commits")
                .font(.headline)
            Spacer()
            Toggle("Auto", isOn: $autoCommitEnabled)
        }
    }
}
