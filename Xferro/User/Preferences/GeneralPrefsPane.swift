import SwiftUI

struct GeneralPrefsPane: View {
    let defaults: UserDefaults
    let config: GitConfig

    @ConfigValue var userName: String
    @ConfigValue var userEmail: String
    @AppStorage var autoCommitEnabled: Bool
    @AppStorage var autoCommitAndPushEnabled: Bool
    @AppStorage var fetchTags: Bool

    var body: some View {
        Form {
            LabeledContent("Work in progress options:") {
                VStack(alignment: .leading) {
                    Toggle("Automaticaly commit on save", isOn: $autoCommitEnabled)
                    Toggle("Automatically push wip commits", isOn: $autoCommitAndPushEnabled)
                }
                .fixedSize()
            }
            TextField("User name:", text: $userName)
            TextField("User email:", text: $userEmail)
            LabeledContent("Fetch options:") {
                VStack(alignment: .leading) {
                    Toggle("Download tags", isOn: $fetchTags)
                }
                .fixedSize()
            }
        }
        .frame(minWidth: 350)
    }

    init(defaults: UserDefaults, config: GitConfig) {
        self.defaults = defaults
        self.config = config
        self._autoCommitEnabled = .init(
            wrappedValue: false,
            PreferenceKeys.autoCommitEnabled,
            store: defaults
        )
        self._autoCommitAndPushEnabled = .init(
            wrappedValue: false,
            PreferenceKeys.autoCommitAndPushEnabled,
            store: defaults
        )

        self._userName = .init(
            key: "user.name",
            config: config,
            default: ""
        )
        self._userEmail = .init(
            key: "user.email",
            config: config,
            default: ""
        )
        self._fetchTags = .init(
            wrappedValue: false,
            PreferenceKeys.fetchTags,
            store: defaults
        )
    }
}
