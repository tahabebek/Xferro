//
//  CommitsViewModel+Keys.swift
//  Xferro
//
//  Created by Taha Bebek on 2/27/25.
//

import Foundation

extension CommitsViewModel {
    func kGitWatcher(_ repository: Repository) -> String {
        String("git_watch_" + repository.gitDir.path)
    }
    func kFolderWatcher(_ repository: Repository) -> String {
        String("folder_watch_" + repository.gitDir.path)
    }
    func kRepositoryInfo(_ repository: Repository) -> String {
        String("info_" + repository.gitDir.path())
    }
    func kFolderObserver(_ repository: Repository) -> String {
        String("folder_observe_" + repository.gitDir.path())
    }
    func kGitObserver(_ repository: Repository) -> String {
        String("git_observe_" + repository.gitDir.path())
    }
}
