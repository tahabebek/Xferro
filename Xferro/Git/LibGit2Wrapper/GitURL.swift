//
//  GitURL.swift
//  Xferro
//
//  Created by Taha Bebek on 1/12/25.
//

import Foundation

struct GitURL {
    init?(_ git: String) {
        guard let regex = try? NSRegularExpression(pattern: "^((.*):\\/\\/)?((.*)@)?(.*?)[:|\\/](.*?)\\/(.*?)(.git)?$", options: []),
              let result = regex.firstMatch(in: git, range: NSMakeRange(0, git.count)) else {
            return nil
        }
        let nsString = git as NSString
        let matchData = (0..<result.numberOfRanges).map { (index) -> String? in
            let range = result.range(at: index)
            if range.location == NSNotFound {
                return nil
            } else {
                return nsString.substring(with: range)
            }
        }
        scheme = matchData[2]?.lowercased() ?? "ssh"
        user = matchData[4]
        host = matchData[5]!
        group = matchData[6]!
        project = matchData[7]!
    }

    private(set) var scheme: String
    private(set) var host: String
    private(set) var user: String?
    private(set) var group: String
    private(set) var project: String
}
