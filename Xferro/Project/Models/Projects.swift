//
//  Projects.swift
//  Xferro
//
//  Created by Taha Bebek on 1/8/25.
//

class Projects: Codable {
    var currentProject: Project?
    let projects: Set<Project>

    init(currentProject: Project? = nil, projects: Set<Project>) {
        self.currentProject = currentProject
        self.projects = projects
    }
}
