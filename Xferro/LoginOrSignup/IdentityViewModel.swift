//
//  IdentityViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import Foundation
import Observation

@Observable final class IdentityViewModel {
    var name: String = ""
    var email: String = ""

    @ObservationIgnored var onIdentityEntered: ((CommitIdentity) -> Void)?

    func finishButtonTapped() {
        onIdentityEntered?(CommitIdentity(name: name.isEmpty ? "Author" : name, email: email.isEmpty ? "author@example.com" : email))
    }
}
