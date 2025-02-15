//
//  StatusManager.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

final class StatusManager {
    static let shared = StatusManager()

    private init() {}

    func status(of repository: Repository) -> [StatusEntry] {
        repository.status(options: [
            .recurseUntrackedDirs,
            .includeUntracked,
            .renamesFromRewrites,
            .renamesHeadToIndex,
            .renamesIndexToWorkdir,
            .sortCaseSensitively,
            .updateIndex
        ]).mustSucceed()
    }
}
