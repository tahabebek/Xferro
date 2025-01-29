//
//  PushOptions.swift
//  SwiftGit2
//
//  Created by Whirlwind on 2019/6/30.
//  Copyright © 2019 GitHub, Inc. All rights reserved.
//

import Cocoa

class PushOptions: NSObject {
    typealias MessageBlock = RemoteCallback.MessageBlock
    typealias ProgressBlock = RemoteCallback.ProgressBlock

    var remoteCallback: RemoteCallback

    init(url: String,
         messageBlock: MessageBlock? = nil,
         progressBlock: ProgressBlock? = nil) {
        self.remoteCallback = RemoteCallback(
            mode: .Push,
            url: url,
            messageBlock: messageBlock,
            progressBlock: progressBlock)
    }

    func toGit() -> git_push_options {
        let pointer = UnsafeMutablePointer<git_push_options>.allocate(capacity: 1)
        git_push_options_init(pointer, UInt32(GIT_PUSH_OPTIONS_VERSION))

        var options = pointer.move()

        pointer.deallocate()

        options.pb_parallelism = 0
        options.callbacks = remoteCallback.toGit()
        return options
    }
}
