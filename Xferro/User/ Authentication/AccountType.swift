import Foundation

enum AccountType: Int, CaseIterable, Sendable {
    case gitHub = 0
    case gitLab = 1
    case bitbucketCloud = 2
    case bitbucketServer = 3
    case teamCity = 4

    enum Names {
        static let gitHub = "github"
        static let gitLab = "gitlab"
        static let bitbucketCloud = "bitbucketCloud"
        static let bitbucketServer = "bitbucketServer"
        static let teamCity = "teamCity"
    }

    init?(name: String?) {
        guard let name else { return nil }
        switch name {
        case Names.gitHub:
            self = .gitHub
        case Names.gitLab:
            self = .gitLab
        case Names.bitbucketCloud:
            self = .bitbucketCloud
        case Names.bitbucketServer:
            self = .bitbucketServer
        case Names.teamCity:
            self = .teamCity
        default:
            return nil
        }
    }

    var name: String {
        switch self {
        case .gitHub: Names.gitHub
        case .gitLab: Names.gitLab
        case .bitbucketCloud: Names.bitbucketCloud
        case .bitbucketServer: Names.bitbucketServer
        case .teamCity: Names.teamCity
        }
    }

    var displayName: String {
        switch self {
        case .gitHub: "GitHub"
        case .gitLab: "GitLab"
        case .bitbucketCloud: "Bitbucket Cloud"
        case .bitbucketServer: "Bitbucket Server"
        case .teamCity: "TeamCity"
        }
    }

    var defaultLocation: String {
        switch self {
        case .gitHub: "" // "https://api.github.com"
        case .gitLab: ""
        case .bitbucketCloud: "" // "https://api.bitbucket.org"
        case .bitbucketServer: ""
        case .teamCity: ""
        }
    }

    /// True if the service uses an API and therefore needs the location to be set
    var needsLocation: Bool {
        switch self {
        case .gitHub, .gitLab, .bitbucketCloud: false
        case .bitbucketServer, .teamCity: true
        }
    }

    var imageName: NSImage.Name {
        switch self {
        case .gitHub: .xtGitHub
        case .gitLab: .xtGitLab
        case .bitbucketCloud, .bitbucketServer: .xtBitBucketTemplate
        case .teamCity: .xtTeamCity
        }
    }
}

extension NSImage.Name
{
    static let xtBitBucketTemplate = "bitbucketTemplate"
    static let xtGitHub = "github"
    static let xtGitLab = "gitlab"
    static let xtTeamCity = "teamcity"
}
