//
//  DataModelView.swift
//  Xferro
//
//  Created by Taha Bebek on 3/14/25.
//

import SwiftUI
/// A view with a specific data model type.
protocol DataModelView: View {
    associatedtype Model: ObservableObject, Validating
    init(model: Model)
}
