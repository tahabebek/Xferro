//
//  PaywallView.swift
//  Xferro
//
//  Created by Taha Bebek on 4/2/25.
//

import SwiftUI
import StoreKit

let productIdentifiers: Set<String> = ["com.xferro.pro.monthly", "com.xferro.pro.yearly"]

struct PaywallView: View {
    var body: some View {
        SubscriptionStoreView(productIDs: productIdentifiers) {
            VStack(spacing: 16) {
                Image(systemName: "dollarsign.square.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.accentColor)
                    .frame(height: 80)
                
                Text("Unlock Xferro Pro")
            }
            .font(.heading0)
            .bold()
        }
    }
}
