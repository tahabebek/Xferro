import SwiftUI

enum ButtonType {
    case cancel
    case accept(String)
    case other(String)

    static let ok: Self = .accept(UIString.ok.rawValue)

    static func accept(_ uiString: UIString) -> ButtonType {
        .accept(uiString.rawValue)
    }

    var title: String {
        switch self {
        case .cancel: UIString.cancel.rawValue
        case .accept(let text), .other(let text): text
        }
    }

    var keyboardShortcut: KeyboardShortcut? {
        switch self {
        case .cancel: .cancelAction
        case .accept: .defaultAction
        default: nil
        }
    }

    var isAccept: Bool {
        switch self {
        case .accept: true
        default: false
        }
    }
}

extension ButtonType: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
}

protocol Validating {
    /// Returns true if the object has valid values.
    ///
    /// Implementations should be `@Published` so that buttons will update
    /// immediately.
    var isValid: Bool { get }
}

/// For types that need to conform to `Validating` but are always valid.
protocol AlwaysValid: Validating {}
extension AlwaysValid {
    var isValid: Bool { true }
}

typealias ButtonAction = () -> Void
typealias ButtonList = [(ButtonType, ButtonAction)]

/// A row of buttons, as specified in the `.buttons` environment value.
struct DialogButtonRow<V>: View where V: ObservableObject & Validating {
    @ObservedObject var validator: V
    let buttons: ButtonList

    var body: some View
    {
        HStack {
            Spacer()
            ForEach(buttons, id: \.0) {
                Button($0.0.title, action: $0.1)
                    .keyboardShortcut($0.0.keyboardShortcut)
                    .disabled($0.0.isAccept && !validator.isValid)
            }
        }
        .padding([.top])
    }
}
