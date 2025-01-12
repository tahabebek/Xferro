//
//  Submodule+UpdateOptions.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

extension Submodule {
    class UpdateOptions {
        var fetchOptions: FetchOptions
        var checkoutOptions: CheckoutOptions

        init(fetchOptions: FetchOptions, checkoutOptions: CheckoutOptions? = nil) {
            self.fetchOptions = fetchOptions
            self.checkoutOptions = checkoutOptions ?? CheckoutOptions()
        }

        func toGitOptions() -> git_submodule_update_options {
            let pointer = UnsafeMutablePointer<git_submodule_update_options>.allocate(capacity: 1)
            git_submodule_update_options_init(pointer, UInt32(GIT_SUBMODULE_UPDATE_OPTIONS_VERSION))

            var options = pointer.move()

            pointer.deallocate()

            options.checkout_opts = checkoutOptions.toGit()
            options.fetch_opts = fetchOptions.toGit()

            return options
        }
    }

}

