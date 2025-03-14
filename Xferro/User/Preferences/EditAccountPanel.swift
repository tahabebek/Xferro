import SwiftUI

struct EditAccountPanel: DataModelView {
    typealias Model = AccountInfo

    @ObservedObject var model: AccountInfo

    init() {
        self.model = .init()
    }

    init(model: AccountInfo) {
        self.model = model
    }

    var body: some View {
        Form {
            Picker("Services:", selection: $model.serviceType) {
                ForEach(AccountType.allCases, id: \.self) { type in
                    ServiceLabel(type)
                }
            }
            TextField("Location:", text: $model.location)
            TextField("User name:", text: $model.userName)
            SecureField("Password:", text: $model.password)
        }
        .frame(minWidth: 300)
    }
}
