//
//  GGBranchSettings.swift
//  Xferro
//
//  Created by Taha Bebek on 1/29/25.
//

import Foundation

struct GGBranchSettings {
    let persistence: [NSRegularExpression]
    let order: [NSRegularExpression]
    let terminalColors: [(pattern: NSRegularExpression, colors: [String])]
    let terminalColorsUnknown: [String]
    let svgColors: [(pattern: NSRegularExpression, colors: [String])]
    let svgColorsUnknown: [String]

    static func from(_ def: GGBranchSettingsDef) throws -> GGBranchSettings {
        let persistence = try def.persistence.map { pattern in
            try NSRegularExpression(pattern: pattern, options: [])
        }

        let order = try def.order.map { pattern in
            try NSRegularExpression(pattern: pattern, options: [])
        }

        let terminalColors = try def.terminalColors.matches.map { pattern, colors in
            (try NSRegularExpression(pattern: pattern, options: []), colors)
        }

        let svgColors = try def.svgColors.matches.map { pattern, colors in
            (try NSRegularExpression(pattern: pattern, options: []), colors)
        }

        return GGBranchSettings(
            persistence: persistence,
            order: order,
            terminalColors: terminalColors,
            terminalColorsUnknown: def.terminalColors.unknown,
            svgColors: svgColors,
            svgColorsUnknown: def.svgColors.unknown
        )
    }
}

struct GGBranchSettingsDef {
    let persistence: [String]
    let order: [String]
    let terminalColors: GGColorsDef
    let svgColors: GGColorsDef
}

extension GGBranchSettingsDef {
    /// The Git-Flow model
    static func gitFlow() -> Self {
        GGBranchSettingsDef(
            persistence: [
                "^(master|main|trunk)$",
                "^(develop|dev)$",
                "^feature.*$",
                "^release.*$",
                "^hotfix.*$",
                "^bugfix.*$"
            ],
            order: [
                "^(master|main|trunk)$",
                "^(hotfix|release).*$",
                "^(develop|dev)$"
            ],
            terminalColors: GGColorsDef(
                matches: [
                    ("^(master|main|trunk)$", ["bright_blue"]),
                    ("^(develop|dev)$", ["bright_yellow"]),
                    ("^(feature|fork/).*$", ["bright_magenta", "bright_cyan"]),
                    ("^release.*$", ["bright_green"]),
                    ("^(bugfix|hotfix).*$", ["bright_red"]),
                    ("^tags/.*$", ["bright_green"])
                ],
                unknown: ["white"]
            ),
            svgColors: GGColorsDef(
                matches: [
                    ("^(master|main|trunk)$", ["blue"]),
                    ("^(develop|dev)$", ["orange"]),
                    ("^(feature|fork/).*$", ["purple", "turquoise"]),
                    ("^release.*$", ["green"]),
                    ("^(bugfix|hotfix).*$", ["red"]),
                    ("^tags/.*$", ["green"])
                ],
                unknown: ["gray"]
            )
        )
    }

    /// Simple feature-based model
    static func simple() -> Self {
        GGBranchSettingsDef(
            persistence: ["^(master|main|trunk)$"],
            order: [
                "^tags/.*$",
                "^(master|main|trunk)$"
            ],
            terminalColors: GGColorsDef(
                matches: [
                    ("^(master|main|trunk)$", ["bright_blue"]),
                    ("^tags/.*$", ["bright_green"])
                ],
                unknown: [
                    "bright_yellow",
                    "bright_green",
                    "bright_red",
                    "bright_magenta",
                    "bright_cyan"
                ]
            ),
            svgColors: GGColorsDef(
                matches: [
                    ("^(master|main|trunk)$", ["blue"]),
                    ("^tags/.*$", ["green"])
                ],
                unknown: [
                    "orange",
                    "green",
                    "red",
                    "purple",
                    "turquoise"
                ]
            )
        )
    }

    /// Very simple model without any defined branch roles
    static func none() -> Self {
        GGBranchSettingsDef(
            persistence: [],
            order: [],
            terminalColors: GGColorsDef(
                matches: [],
                unknown: [
                    "bright_blue",
                    "bright_yellow",
                    "bright_green",
                    "bright_red",
                    "bright_magenta",
                    "bright_cyan"
                ]
            ),
            svgColors: GGColorsDef(
                matches: [],
                unknown: [
                    "blue",
                    "orange",
                    "green",
                    "red",
                    "purple",
                    "turquoise"
                ]
            )
        )
    }
}
