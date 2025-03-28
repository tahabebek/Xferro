import SwiftUI

struct SettingsView: View {
    let defaults: UserDefaults
    let config: GitConfig

    @ConfigValue var userName: String
    @ConfigValue var userEmail: String
    @AppStorage var autoCommitEnabled: Bool
    @AppStorage var autoPushEnabled: Bool

    let initialUserName: String
    let initialUserEmail: String
    let initialAutoCommitEnabled: Bool
    let initialAutoPushEnabled: Bool

    let onSave: () -> Void

    init(defaults: UserDefaults, config: GitConfig, onSave: @escaping () -> Void) {
        self.defaults = defaults
        self.config = config

        let commitEnabled = AppStorage(
            wrappedValue: false,
            PreferenceKeys.autoCommitEnabled,
            store: defaults
        )

        let pushEnabled = AppStorage(
            wrappedValue: false,
            PreferenceKeys.autoPushEnabled,
            store: defaults
        )

        let name = ConfigValue(
            key: "user.name",
            config: config,
            default: ""
        )

        let email = ConfigValue(
            key: "user.email",
            config: config,
            default: ""
        )

        self._autoCommitEnabled = commitEnabled
        self._autoPushEnabled = pushEnabled
        self._userName = name
        self._userEmail = email
        self.initialUserName = name.wrappedValue
        self.initialUserEmail = email.wrappedValue
        self.initialAutoPushEnabled = pushEnabled.wrappedValue
        self.initialAutoCommitEnabled = commitEnabled.wrappedValue
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
                    XFButton<Void>(
                        title: "Cancel",
                        isProminent: false,
                        onTap: {
                            $userName.wrappedValue = initialUserName
                            $userEmail.wrappedValue = initialUserEmail
                            autoCommitEnabled = initialAutoCommitEnabled
                            autoPushEnabled = initialAutoPushEnabled
                            onSave()
                        }
                    )

                    XFButton<Void>(
                        title: "Save",
                        onTap: {
                            onSave()
                        }
                    )
                }
            }
        } header: {
            Text("Settings")
                .padding()
        }
        .padding()
        .frame(minWidth: 350)
    }
}
