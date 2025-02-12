//
//  Repository+Submodule.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

typealias SubmoduleEachBlock = (Submodule) -> Int32

extension Repository {
    private struct CallbackContext {
        let block: SubmoduleEachBlock
        let lock: NSRecursiveLock
    }

    private static let gitSubmoduleCallbackFunction: git_submodule_cb = { submodule, name, payload in
        guard let submodule = submodule, let payload = payload else {
            return GIT_ERROR.rawValue
        }

        let context = payload.assumingMemoryBound(to: CallbackContext.self).pointee
        let obj = Submodule(pointer: submodule, autorelease: false, lock: context.lock)
        return context.block(obj)
    }

    @discardableResult
    func eachSubmodule(_ block: @escaping SubmoduleEachBlock) -> NSError? {
        lock.lock()
        defer { lock.unlock() }
        var context = CallbackContext(block: block, lock: lock)
        return withUnsafePointer(to: &context) { contextPtr -> NSError? in
            let result = git_submodule_foreach(
                self.pointer,
                Repository.gitSubmoduleCallbackFunction,
                UnsafeMutableRawPointer(mutating: contextPtr)
            )
            if result == GIT_OK.rawValue {
                return nil
            }
            return NSError(gitError: result, pointOfFailure: "git_submodule_foreach")
        }
    }

    private func eachRepository(name: String, block: @escaping (String, Repository) -> Bool) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if !block(name, self) { return false }
        let name = name.isEmpty ? name : name + "/"
        eachSubmodule { (submodule) -> Int32 in
            if let repo = submodule.repository {
                if !repo.eachRepository(name: "\(name)\(submodule.name)", block: block) { return GIT_ERROR.rawValue }
            }
            return GIT_OK.rawValue
        }
        return true
    }

    @discardableResult
    func eachRepository(_ block: @escaping (String, Repository) -> Bool) -> Bool {
        return eachRepository(name: "", block: block)
    }

    func submodules() -> [Submodule] {
        var names = [String]()
        self.eachSubmodule {
            names.append($0.name)
            return GIT_OK.rawValue
        }
        return names.map { try! self.submodule(for: $0).get() }
    }

    func submodule(for name: String) -> Result<Submodule, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var module: OpaquePointer?
        let result = name.withCString {
            git_submodule_lookup(&module, self.pointer, $0)
        }
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_submodule_lookup"))
        }
        return .success(Submodule(pointer: module!, lock: lock))
    }
}

