//
//  ForgotPasswordViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/16/25.
//

import Foundation
import Observation

@Observable class ForgotPasswordViewModel: Identifiable {
    var id: UUID = UUID()

    var email: String = ""
    @ObservationIgnored let onSendButtonTapped: (String) -> Void

    init(onSendButtonTapped: @escaping (String) -> Void) {
        self.onSendButtonTapped = onSendButtonTapped
    }

    func sendButtonTapped() {
        onSendButtonTapped(email)
    }
}
