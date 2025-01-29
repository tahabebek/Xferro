//
//  Projects.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

import Observation

@Observable final class Projects: Codable {
    var currentProject: Project?
    var recentProjects: Set<Project>

    init(currentProject: Project? = nil, recentProjects: Set<Project>) {
        self.currentProject = currentProject
        self.recentProjects = recentProjects
    }
}
