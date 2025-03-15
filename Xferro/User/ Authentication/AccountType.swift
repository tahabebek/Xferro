import Foundation

enum AccountType: Int, CaseIterable, Sendable {
    case gitHub = 0
    case gitHubEnterprise = 1
    case bitbucketCloud = 2
    case bitbucketServer = 3
    case gitLab = 4
    case gitLabSelfHosted = 5

    enum Names {
        static let gitHub = "github"
        static let gitHubEnterprise = "githubEnterprise"
        static let bitbucketCloud = "bitbucketCloud"
        static let bitbucketServer = "bitbucketServer"
        static let gitLab = "gitlab"
        static let gitLabSelfHosted = "gitLabSelfHosted"
    }

    init?(name: String?) {
        guard let name else { return nil }
        switch name {
        case Names.gitHub:
            self = .gitHub
        case Names.gitHubEnterprise:
            self = .gitHubEnterprise
        case Names.bitbucketCloud:
            self = .bitbucketCloud
        case Names.bitbucketServer:
            self = .bitbucketServer
        case Names.gitLab:
            self = .gitLab
        case Names.gitLabSelfHosted:
            self = .gitLabSelfHosted
        default:
            return nil
        }
    }

    var name: String {
        switch self {
        case .gitHub: Names.gitHub
        case .gitHubEnterprise: Names.gitHubEnterprise
        case .bitbucketCloud: Names.bitbucketCloud
        case .bitbucketServer: Names.bitbucketServer
        case .gitLab: Names.gitLab
        case .gitLabSelfHosted: Names.gitLabSelfHosted
        }
    }

    var tokenURL: URL {
        switch self {
        case .gitHub:
            URL(string: "https://github.com/settings/tokens/new")!
        case .gitHubEnterprise:
            URL(string: "https://github.com/settings/tokens/new")!
        case .bitbucketCloud:
            URL(string: "https://support.atlassian.com/bitbucket-cloud/docs/app-passwords/")!
        case .bitbucketServer:
            URL(string: "https://confluence.atlassian.com/bitbucketserver/personal-access-tokens-939515499.html")!
        case .gitLab:
            URL(string: "https://docs.gitlab.com/user/profile/personal_access_tokens")!
        case .gitLabSelfHosted:
            URL(string: "https://docs.gitlab.com/user/profile/personal_access_tokens")!
        }
    }

    var displayName: String {
        switch self {
        case .gitHub: "GitHub"
        case .gitHubEnterprise: "Github Enterprise"
        case .bitbucketCloud: "Bitbucket Cloud"
        case .bitbucketServer: "Bitbucket Server"
        case .gitLab: "GitLab"
        case .gitLabSelfHosted: "GitLab Self-Hosted"
        }
    }

    var defaultLocation: String {
        switch self {
        case .gitHub: "" // "https://api.github.com"
        case .gitHubEnterprise: ""
        case .bitbucketCloud: "" // "https://api.bitbucket.org"
        case .bitbucketServer: ""
        case .gitLab: ""
        case .gitLabSelfHosted: ""
        }
    }

    /// True if the service uses an API and therefore needs the location to be set
    var needsLocation: Bool {
        switch self {
        case .gitHub, .gitLab, .bitbucketCloud: false
        case .bitbucketServer, .gitHubEnterprise, .gitLabSelfHosted: true
        }
    }

    var imageName: NSImage.Name {
        switch self {
        case .gitHub, .gitHubEnterprise: .GitHub
        case .gitLab, .gitLabSelfHosted: .GitLab
        case .bitbucketCloud, .bitbucketServer: .BitBucketTemplate
        }
    }
}

extension NSImage.Name
{
    static let BitBucketTemplate = "bitbucketTemplate"
    static let GitHub = "github"
    static let GitLab = "gitlab"
}
