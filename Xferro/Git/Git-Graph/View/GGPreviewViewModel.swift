//
//  GGPreviewData.swift
//  Xferro
//
//  Created by Taha Bebek on 1/30/25.
//

import SwiftUI

struct GGPreviewViewModel: PreviewModifier {

    static var sharedViewModel: GGViewModel {
        print("create shared view model")
        let path = Bundle.main.path(forResource: "annoy_git_graph", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let encoder = JSONDecoder()
        let gitGraph = try! encoder.decode(GitGraph.self, from: data)
        return GGViewModel(gitGraph: gitGraph)
    }

    static func makeSharedContext() async throws -> GGViewModel {
        sharedViewModel
    }

    func body(content: Content, context: GGViewModel) -> some View {
        // Inject the object into the view to preview.
        content
            .environment(context)
    }
}
