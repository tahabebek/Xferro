//
//  AddRepositoryButton.swift
//  Xferro
//
//  Created by Taha Bebek on 2/4/25.
//

import SwiftUI

struct AddRepositoryButton: View {
    
    let onTapNewRepository: () -> Void
    let onTapAddLocalRepository: () -> Void
    let onTapCloneRepository: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            XFButton<Void,Text>(
                title: "New Repository",
                onTap: {
                    onTapNewRepository()
                }
            )
            XFButton<Void,Text>(
                title: "Add Local Repository",
                onTap: {
                    onTapAddLocalRepository()
                }
            )
            XFButton<Void,Text>(
                title: "Clone Repository",
                onTap: {
                    onTapCloneRepository()
                }
            )
        }
    }
}
