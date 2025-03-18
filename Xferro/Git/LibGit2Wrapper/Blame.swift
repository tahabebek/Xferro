//
//  Blame.swift
//  Xferro
//
//  Created by Taha Bebek on 2/25/25.
//

import Foundation

public struct BlameHunk: Sendable
{
    struct LineInfo: Sendable
    {
        let oid: OID // OIDs are zero for local changes
        let start: Int
        let signature: Signature
    }

    fileprivate(set) var lineCount: Int
    let boundary: Bool

    let originalLine: LineInfo
    let finalLine: LineInfo

    init(lineCount: Int, boundary: Bool,
         originalLine: LineInfo, finalLine: LineInfo)
    {
        self.lineCount = lineCount
        self.boundary = boundary
        self.originalLine = originalLine
        self.finalLine = finalLine
    }
}

// TODO: Make this Sendable because `hunks` is never changed after init
/// Blame data from the git command line because libgit2 is slow
public final class Blame
{
    public var hunks = [BlameHunk]()

    func read(text: String, from repository: Repository) -> Bool
    {
        var startHunk = true

        for line in text.lines {
            if startHunk {
                let parts = line.components(separatedBy: .whitespaces)
                guard parts.count >= 3,
                      let sha = SHA(parts[0]),
                      let oid = OID(sha: sha)
                else { continue }

                if var last = hunks.last,
                   oid == last.originalLine.oid {
                    last.lineCount += 1
                    hunks[hunks.index(before: hunks.endIndex)] = last
                }
                else {
                    guard let originalLine = Int(parts[1]),
                          let finalLine = Int(parts[2])
                    else { continue }

                    var authorSig, committerSig: Signature!

                    if oid.isZero {
                        authorSig = Signature.default(repository).mustSucceed(repository.gitDir)
                        committerSig = authorSig
                    }
                    else {
                        let commit = repository.commit(oid).mustSucceed(repository.gitDir)

                        authorSig = commit.author
                        committerSig = commit.committer
                    }

                    // The output doesn't have the original commit SHA so fake it
                    // by using author/committer
                    let hunk = BlameHunk(lineCount: 1, boundary: false,
                                         originalLine: BlameHunk.LineInfo(
                                            oid: oid, start: originalLine,
                                            signature: authorSig),
                                         finalLine: BlameHunk.LineInfo(
                                            oid: oid, start: finalLine,
                                            signature: committerSig))

                    hunks.append(hunk)
                }
                startHunk = false
            }
            else if line.hasPrefix("\t") {
                // This line has the text from the file after the tab
                // but we're not collecting that here.
                startHunk = true
            }
            // Other lines that don't start with a tab have author & committer
            // info, but we're getting that from the commit.
        }
        return true
    }

    init?(repository: Repository, path: String, from startOID: OID?, to endOID: OID?)
    {
        var args = ["blame", "-p", path]

        if let sha = startOID?.sha {
            args.insert(contentsOf: [sha.rawValue, "--"], at: 2)
        }

        let output = try! GitCLI.executeGit(repository, args)
        guard read(text: output, from: repository) else { return nil }
    }

    init?(repository: Repository, path: String, data: Data, to endOID: OID?)
    {
        let args = ["blame", "-p", "--contents", "-", path]
        let output = try! GitCLI.executeGit(repository, args)
        guard read(text: output, from: repository) else { return nil }
    }
}
