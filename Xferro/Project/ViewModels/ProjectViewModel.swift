//
//  ProjectViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 1/9/25.
//

import Observation

@Observable
class ProjectViewModel {
    var project: Project

    init(project: Project) {
        self.project = project
    }
}
