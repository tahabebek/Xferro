//
//  RepositoryEmptyView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/3/25.
//

import SwiftUI

struct RepositoryEmptyView: View {
    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                Text("Empty")
                Spacer()
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
