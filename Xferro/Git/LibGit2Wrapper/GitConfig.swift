//
//  GitConfig.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

class Config {
    enum Level: Int32 {
        /** System-wide configuration file; /etc/gitconfig on Linux systems */
        case system         = 2     // GIT_CONFIG_LEVEL_SYSTEM

        /** XDG compatible configuration file; typically ~/.config/git/config */
        case xdg            = 3     // GIT_CONFIG_LEVEL_XDG

        /** User-specific configuration file (also called Global configuration
         * file); typically ~/.gitconfig
         */
        case global         = 4     // GIT_CONFIG_LEVEL_GLOBAL

        /** Repository specific configuration file; $WORK_DIR/.git/config on
         * non-bare repos
         */
        case repository     = 5     // GIT_CONFIG_LEVEL_LOCAL

        /** Application specific configuration file; freely defined by applications
         */
        case application    = 6     // GIT_CONFIG_LEVEL_APP

        /** Represents the highest level available config file (i.e. the most
         * specific config file available that actually is loaded)
         */
        case highest        = -1    // GIT_CONFIG_HIGHEST_LEVEL
    }

    struct Entry {
        var name: String; /**< Name of the entry (normalised) */
        var value: String; /**< String value of the entry */
        var include_depth: UInt32; /**< Depth of includes where this variable was found */
        var level: Level; /**< Which config file this was found in */
    }

    var config: OpaquePointer
    private var lock: NSRecursiveLock
    private init(_ config: OpaquePointer, lock: NSRecursiveLock) {
        self.config = config
        self.lock = lock
    }

    deinit {
        git_config_free(self.config)
    }

    private class func open(path: UnsafePointer<Int8>, lock: NSRecursiveLock) -> Result<Config, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var config: OpaquePointer?
        let result = git_config_open_ondisk(&config, path)
        if result != GIT_OK.rawValue {
            return .failure(NSError(gitError: result, pointOfFailure: "git_config_open_ondisk"))
        }
        return .success(Config(config!, lock: lock))
    }

    class func open(path: String, lock: NSRecursiveLock) -> Result<Config, NSError> {
        return path.withCString { open(path: $0, lock: lock) }
    }

    class func open(repository: Repository) -> Result<Config, NSError> {
        repository.lock.lock()
        defer { repository.lock.unlock() }
        var config: OpaquePointer?
        let result = git_repository_config(&config, repository.pointer)
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_repository_config"))
        }
        let cfg = Config(config!, lock: repository.lock)
        if repository.isWorkTree,
           (try? cfg.usingWorktree().get()) == true,
           let worktreeConfigPath = repository.worktreeConfigPath
        {
            try? cfg.addConfig(path: worktreeConfigPath, level: .application, repo: repository.pointer).get()
        }
        return .success(cfg)
    }

    class func open(level: Level, lock: NSRecursiveLock) -> Result<Config, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var buf = git_buf()
        defer { git_buf_dispose(&buf) }
        switch level {
        case .system:
            guard git_config_find_system(&buf) == 0 else {
                return .failure(NSError(gitError: GIT_ENOTFOUND.rawValue, pointOfFailure: "git_config_find_system"))
            }
        case .xdg:
            guard git_config_find_xdg(&buf) == 0 else {
                return .failure(NSError(gitError: GIT_ENOTFOUND.rawValue, pointOfFailure: "git_config_find_xdg"))
            }
        case .global:
            guard git_config_find_global(&buf) == 0 else {
                return .failure(NSError(gitError: GIT_ENOTFOUND.rawValue, pointOfFailure: "git_config_find_global"))
            }
        default:
            return .failure(NSError(gitError: GIT_ERROR.rawValue, pointOfFailure: "could not find configuration for level `\(level)`"))

        }
        return open(path: buf.ptr, lock: lock)
    }

    class func `default`(lock: NSRecursiveLock) -> Result<Config, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var config: OpaquePointer?
        let result = git_config_open_default(&config)
        guard result == GIT_OK.rawValue else {
            return Result.failure(NSError(gitError: result, pointOfFailure: "git_config_open_default"))
        }
        return .success(Config(config!, lock: lock))
    }

    private func snapshot() -> OpaquePointer {
        lock.lock()
        defer { lock.unlock() }
        var snapshot: OpaquePointer?
        git_config_snapshot(&snapshot, config)
        return snapshot!
    }

    private func writableConfig() -> OpaquePointer? {
        lock.lock()
        defer { lock.unlock() }
        var config: OpaquePointer?
        let result = git_config_open_level(&config, self.config, GIT_CONFIG_LEVEL_LOCAL)
        guard result == GIT_OK.rawValue else {
            return nil
        }
        return config
    }

    func addConfig(path: String, level: Level, repo: OpaquePointer? = nil) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let result = path.withCString {
            git_config_add_file_ondisk(config, $0, git_config_level_t(rawValue: level.rawValue), repo, 1)
        }
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_config_add_file_ondisk"))
        }
        return .success(())
    }

    func pickConfig(level: Level) -> Result<Config, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var config: OpaquePointer?
        let result = git_config_open_level(&config, self.config, git_config_level_t(rawValue: level.rawValue))
        guard result == GIT_OK.rawValue else {
            return .failure(NSError(gitError: result, pointOfFailure: "git_config_open_level"))
        }
        return .success(Config(config!, lock: lock))
    }

    func delete(keyPath: String) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let result = keyPath.withCString { git_config_delete_entry(self.writableConfig(), $0) }
        switch result {
        case GIT_ENOTFOUND.rawValue, GIT_OK.rawValue:
            return .success(())
        default:
            return .failure(NSError(gitError: result, pointOfFailure: "git_config_delete_entry"))
        }
    }

    func strings(for keyPath: String) -> Result<[(value: String, depth: UInt32)]?, NSError> {
        lock.lock()
        defer { lock.unlock() }
        return keyPath.withCString { name in
            var iter: UnsafeMutablePointer<git_config_iterator>? = nil
            var result = git_config_multivar_iterator_new(&iter, self.snapshot(), name, nil)
            guard result == GIT_OK.rawValue else {
                return .failure(NSError(gitError: result, pointOfFailure: "git_config_multivar_iterator_new"))
            }
            defer { git_config_iterator_free(iter!) }

            var entry: UnsafeMutablePointer<git_config_entry>! = UnsafeMutablePointer<git_config_entry>.allocate(capacity: 1)
            defer {
                // Do not release entry! It will be released by iter
                // entry.deallocate()
            }
            var data = [(value: String, depth: UInt32)]()
            while (true) {
                result = git_config_next(&entry, iter!)
                if result == GIT_ITEROVER.rawValue { break }
                guard result == GIT_OK.rawValue else {
                    return .failure(NSError(gitError: result, pointOfFailure: "git_config_next"))
                }
                let entryData = entry.pointee
                let value = String(cString: entryData.value)
                let depth = entryData.include_depth
                data.append((value: value, depth: depth))
            }
            return .success(data)
        }
    }

    func string(for keyPath: String) -> Result<String?, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var value: UnsafePointer<Int8>?
        let result = keyPath.withCString { git_config_get_string(&value, snapshot(), $0) }
        switch result {
        case GIT_ENOTFOUND.rawValue:
            return .success(nil)
        case GIT_OK.rawValue:
            return .success(String(cString: value!))
        default:
            return .failure(NSError(gitError: result, pointOfFailure: "git_config_get_string"))
        }
    }

    func bool(for keyPath: String) -> Result<Bool?, NSError> {
        lock.lock()
        defer { lock.unlock() }
        var value: Int32 = 0
        let result = keyPath.withCString { git_config_get_bool(&value, snapshot(), $0) }
        switch result {
        case GIT_ENOTFOUND.rawValue:
            return .success(nil)
        case GIT_OK.rawValue:
            return .success(value == 1)
        default:
            return .failure(NSError(gitError: result, pointOfFailure: "git_config_get_bool"))
        }
    }

    func set(string: String, for keyPath: String) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        return string.withCString { (value) -> Result<Void, NSError> in
            keyPath.withCString { (key) -> Result<Void, NSError> in
                let result = git_config_set_string(self.writableConfig(), key, value)
                guard result == GIT_OK.rawValue else {
                    return .failure(NSError(gitError: result, pointOfFailure: "git_config_set_string"))
                }
                return .success(())
            }
        }
    }

    func set(bool: Bool, for keyPath: String) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        return keyPath.withCString { (key) -> Result<Void, NSError> in
            let result = git_config_set_bool(self.writableConfig(), key, bool ? 1 : 0)
            guard result == GIT_OK.rawValue else {
                return .failure(NSError(gitError: result, pointOfFailure: "git_config_set_bool"))
            }
            return .success(())
        }
    }

    func each(regex: String, block: (git_config_entry) -> Bool) -> Result<Void, NSError> {
        lock.lock()
        defer { lock.unlock() }
        return regex.withCString { regexp in
            var iter: UnsafeMutablePointer<git_config_iterator>? = nil
            git_config_iterator_glob_new(&iter, self.snapshot(), regexp)
            defer { git_config_iterator_free(iter!) }

            var entry: UnsafeMutablePointer<git_config_entry>! = UnsafeMutablePointer<git_config_entry>.allocate(capacity: 1)
            defer {
                // Do not release entry! It will be released by iter
                // entry.deallocate()
            }
            while (true) {
                let result = git_config_next(&entry, iter!)
                guard result != GIT_ITEROVER.rawValue else { break }
                guard result == GIT_OK.rawValue else {
                    return .failure(NSError(gitError: result, pointOfFailure: "git_config_next"))
                }
                if block(entry.pointee) {
                    break
                }
            }
            return .success(())
        }
    }

    func all() -> Result<[String: [Entry]], NSError> {
        lock.lock()
        defer { lock.unlock() }
        var values = [String: [Entry]]()
        var iter: UnsafeMutablePointer<git_config_iterator>? = nil
        git_config_iterator_new(&iter, self.snapshot())
        defer { git_config_iterator_free(iter!) }

        var entry: UnsafeMutablePointer<git_config_entry>! = UnsafeMutablePointer<git_config_entry>.allocate(capacity: 1)
        defer {
            // Do not release entry! It will be released by iter
            // entry.deallocate()
        }
        while (true) {
            let result = git_config_next(&entry, iter!)
            guard result != GIT_ITEROVER.rawValue else { break }
            guard result == GIT_OK.rawValue else {
                return .failure(NSError(gitError: result, pointOfFailure: "git_config_next"))
            }
            let entry = Entry(name: String(cString: entry.pointee.name),
                              value: String(cString: entry.pointee.value),
                              include_depth: entry.pointee.include_depth,
                              level: Level(rawValue: entry.pointee.level.rawValue)!)
            var muliValue = values[entry.name] ?? []
            muliValue.append(entry)
            values[entry.name] = muliValue
        }
        return .success(values)
    }

    // MARK: - Convenience
    func usingWorktree() -> Result<Bool, NSError> {
        return self.bool(for: "extensions.worktreeConfig").map { $0 == true }
    }

    func useWorktree() -> Result<Void, NSError> {
        return self.set(bool: true, for: "extensions.worktreeConfig")
    }

    func insteadOf(originURL: String, direction: Remote.Direction) -> Result<String, NSError> {
        lock.lock()
        defer { lock.unlock() }
        let regexPrefix = "url"
        let regexSuffix = "\(direction == .Push ? "push" : "")insteadof"
        let regex = "\(regexPrefix)\\..*\\.\(regexSuffix)"
        var value = originURL
        return each(regex: regex) { entry in
            let prefix = String(cString: entry.value)
            if originURL.hasPrefix(prefix) {
                let name = String(cString: entry.name)
                let newPrefix = name.dropFirst(regexPrefix.count + 1).dropLast(regexSuffix.count + 1)
                value.replaceSubrange(Range(NSMakeRange(0, prefix.count), in: value)!, with: newPrefix)
                return true
            }
            return false
        }.map {
            return value
        }
    }
}
