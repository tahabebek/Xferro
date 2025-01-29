//
//  FetchOptions.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

class FetchOptions {
    typealias MessageBlock = RemoteCallback.MessageBlock
    typealias ProgressBlock = RemoteCallback.ProgressBlock

    var tags: Bool
    var prune: Bool
    var remoteCallback: RemoteCallback

    init(url: String,
         tags: Bool = true,
         prune: Bool = false,
         credentials: Credentials = .default,
         messageBlock: MessageBlock? = nil,
         progressBlock: ProgressBlock? = nil) {
        self.tags = tags
        self.prune = prune
        self.remoteCallback = RemoteCallback(url: url, messageBlock: messageBlock, progressBlock: progressBlock)
    }

    func toGit() -> git_fetch_options {
        let pointer = UnsafeMutablePointer<git_fetch_options>.allocate(capacity: 1)
        git_fetch_options_init(pointer, UInt32(GIT_FETCH_OPTIONS_VERSION))

        var options = pointer.move()

        pointer.deallocate()

        if tags {
            options.download_tags = GIT_REMOTE_DOWNLOAD_TAGS_ALL
        }
        if prune {
            options.prune = GIT_FETCH_PRUNE
        }

        options.callbacks = remoteCallback.toGit()

        return options
    }
}
