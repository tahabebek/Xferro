//
//  AutoCommitHeaderView.swift
//  Xferro
//
//  Created by Taha Bebek on 2/5/25.
//

import SwiftUI

struct AutoCommitHeaderView: View {
    @AppStorage("autoCommitEnabled") var autoCommitEnabled: Bool = true
    
    var body: some View {
        HStack {
            VerticalHeader(title: "Wip Commits")
            Toggle("Auto", isOn: $autoCommitEnabled)
        }
    }
}
