//
//  BranchListPreviewViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/3/25.
//

import SwiftUI

struct BranchListPreviewViewModel: PreviewModifier {
    static var sharedViewModel: BranchListViewModel {
        let path = Bundle.main.path(forResource: "repository_infos", ofType: "json")
        let data = try! Data(contentsOf: URL(fileURLWithPath: path!))
        let encoder = JSONDecoder()
        let repositoryInfos = try! encoder.decode([BranchListViewModel.RepositoryInfo].self, from: data)
        return BranchListViewModel(repositoryInfos: repositoryInfos)
    }

    static func makeSharedContext() async throws -> BranchListViewModel {
        sharedViewModel
    }

    func body(content: Content, context: BranchListViewModel) -> some View {
        // Inject the object into the view to preview.
        content
            .environment(context)
    }
}
