//
//  ConfigFile.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

extension SSH2 {
    class ConfigFile {
        struct Path {
            static let System = "/etc/ssh/ssh_config"
            static let User = "~/.ssh/config"
        }

        let filePath: String?
        var items: [Any]

        init(filePath: String, items: [Any]) {
            self.filePath = filePath
            self.items = items
        }

        var includes: [String] {
            return items.compactMap { ($0 as? ConfigFile)?.filePath }
        }
        var configs: [Config] {
            var values = [Config]()
            for item in items {
                if let i = item as? ConfigFile {
                    values.append(contentsOf: i.configs)
                } else if let i = item as? Config {
                    values.append(i)
                }
            }
            return values
        }

        func config(for host: String) -> [Config] {
            return self.configs.filter { $0.match(host: host) }
        }

        class func parse(_ filepath: String) -> ConfigFile? {
            let path = (filepath as NSString).expandingTildeInPath
            guard let content = try? String(contentsOfFile: path, encoding: .utf8) else { return nil }
            var items = [Any]()
            for line in content.split(separator: "\n") {
                let line = line.trimmingCharacters(in: .whitespaces)
                if line.isEmpty || line.starts(with: "#") {
                    continue
                }
                var values = line.split(separator: "=").flatMap { $0.split(separator: " ") }.flatMap { $0.split(separator: ",") }.map { String($0) }
                if values.count < 2 { continue }
                let key = values.removeFirst().lowercased()
                if key == "include" {
                    let path = values.joined(separator: " ")
                    if let configFile = ConfigFile.parse(path) {
                        items.append(configFile)
                    }
                } else if key == "host" {
                    items.append(Config(hosts: values))
                } else {
                    if let config = items.last as? Config {
                        config.setup(key: key, values: values)
                    }
                }
            }
            let configFile = ConfigFile(filePath: filepath, items: items)
            return configFile
        }
    }
}
