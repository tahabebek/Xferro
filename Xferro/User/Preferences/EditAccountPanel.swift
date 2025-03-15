import SwiftUI

struct EditAccountPanel: DataModelView {
    typealias Model = AccountInfo

    @ObservedObject var model: AccountInfo
    @Environment(\.openURL) private var openURL

    let cancel: () -> Void
    let addAccountAction: () -> Void

    init(
        model: AccountInfo,
        cancel: @escaping () -> Void,
        addAccountAction: @escaping () -> Void
    ) {
        self.model = model
        self.cancel = cancel
        self.addAccountAction = addAccountAction
    }

    init(model: AccountInfo) {
        self.model = model
        self.cancel = {}
        self.addAccountAction = {}
    }

    var body: some View {
        VStack {
            Form {
                Picker("Services:", selection: $model.serviceType) {
                    ForEach(AccountType.allCases, id: \.self) { type in
                        ServiceLabel(type)
                    }
                }
                TextField("Account:", text: $model.userName)
                TextField(
                    "\(tokenTitleFor(model.serviceType)):",
                    text: $model.password,
                    prompt: Text("\(tokenPromptFor(model.serviceType))")
                )
                TextField(
                    "Server:",
                    text: $model.location,
                    prompt: Text("https://example.com")
                )
                .opacity(model.serviceType.needsLocation ? 1 : 0)
                .padding(.bottom, model.serviceType.needsLocation ? 16 : 0)
            }
            infoFor(model.serviceType)
                .background(Color.fabulaBack2)
                .cornerRadius(8)
                .padding(.bottom)
            HStack {
                XFerroButton(
                    title: createTokenTitleFor(model.serviceType),
                    isProminent: false
                ) {
                    openURL(model.serviceType.tokenURL)
                }
                Spacer()
                XFerroButton(
                    title: "Cancel",
                    isProminent: false
                ) {
                    cancel()
                }
                XFerroButton(
                    title: "Sign In",
                    disabled: disabled(model.serviceType),
                    isProminent: true
                ) {
                    addAccountAction()
                }
            }
        }
        .frame(minWidth: 300)
    }

    @ViewBuilder func infoFor(_ type: AccountType) -> some View {
        if case .gitHub = type {
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Text("GitHub personal access tokens must have these scopes set:")
                        .padding(.bottom, 4)
                    Group {
                        HStack {
                            Text("✓ admin:public_key")
                            Spacer()
                        }
                        HStack {
                            Text("✓ write:discussion")
                            Spacer()
                        }
                        HStack {
                            Text("✓ repo")
                            Spacer()
                        }
                        HStack {
                            Text("✓ user")
                            Spacer()
                        }
                    }
                    .padding(.leading, 8)
                    Spacer()
                }
                Spacer()
            }
        }
    }

    func createTokenTitleFor(_ type: AccountType) -> String {
        switch type {
        case .gitHub:
            "Create a Token on GitHub"
        case .gitHubEnterprise:
            "Create a Token on GitHub Enterprise"
        case .bitbucketCloud:
            "Create a Password on Bitbucket Cloud"
        case .bitbucketServer:
            "Create a Token on Bitbucket Server"
        case .gitLab:
            "Create a Token on GitLab.com"
        case .gitLabSelfHosted:
            "Create a Token on GitLab self-hosted"
        }
    }

    func tokenTitleFor(_ type: AccountType) -> String {
        if case .bitbucketCloud = type {
            "Password"
        } else {
            "Token"
        }
    }

    func tokenPromptFor(_ type: AccountType) -> String {
        if case .bitbucketCloud = type {
            "Enter your App Password"
        } else {
            "Enter your Personal Access Token"
        }
    }

    func disabled(_ type: AccountType) -> Bool {
        if type.needsLocation {
            model.userName.isEmpty || model.password.isEmpty || model.location.isEmpty
        } else {
            model.userName.isEmpty || model.password.isEmpty
        }
    }
}
