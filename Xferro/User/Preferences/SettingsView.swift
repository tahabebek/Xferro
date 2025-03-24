import SwiftUI

struct SettingsView: View {
    let defaults: UserDefaults
    let config: GitConfig

    @ConfigValue var userName: String
    @ConfigValue var userEmail: String
    @AppStorage var autoCommitEnabled: Bool
    @AppStorage var autoPushEnabled: Bool

    let onSave: () -> Void

    init(defaults: UserDefaults, config: GitConfig, onSave: @escaping () -> Void) {
        self.defaults = defaults
        self.config = config
        self._autoCommitEnabled = .init(
            wrappedValue: false,
            PreferenceKeys.autoCommitEnabled,
            store: defaults
        )
        self._autoPushEnabled = .init(
            wrappedValue: false,
            PreferenceKeys.autoPushEnabled,
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
        self.onSave = onSave
    }
    
    var body: some View {
        Section {
            Form {
                HStack {
                    Spacer()
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Automatically commit wip on save")
                            Spacer()
                            Toggle("", isOn: $autoCommitEnabled)
                                .toggleStyle(.switch)
                        }
                        HStack {
                            Text("Automatically push wip commits")
                            Spacer()
                            Toggle("", isOn: $autoPushEnabled)
                                .toggleStyle(.switch)
                        }
                        Divider()
                        TextField("User name:", text: $userName)
                        TextField("User email:", text: $userEmail)
                    }
                    .fixedSize()
                    Spacer()
                }
                .padding(.bottom)
                HStack {
                    Spacer()
                    XFerroButton<Void>(
                        title: "Save and Close",
                        onTap: {
                            onSave()
                        }
                    )
                }
            }
        } header: {
            Text("Settings")
                .padding()
                .font(.headline)
        }
        .padding()
        .frame(minWidth: 350)
    }
}
