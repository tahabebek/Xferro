import SwiftUI

struct AccountStatusCell: View {
    @ObservedObject var service: BasicAuthService

    // Workaround for the fact that @ObservedObject can't handle optionals
    @ViewBuilder
    static func `for`(service: BasicAuthService?) -> some View {
        if let service = service {
            AccountStatusCell(service: service)
        }
        else {
            EmptyView()
        }
    }

    var body: some View {
        let imageName = statusImage(for: service)

        HStack {
            Spacer()
            if service.authenticationStatus == .inProgress {
                ProgressView()
                    .controlSize(.small)
            }
            else {
                Image(nsImage: .init(named: imageName)!)
            }
            Spacer()
        }
    }

    func statusImage(for service: BasicAuthService) -> NSImage.Name {
        switch service.authenticationStatus {
        case .unknown, .notStarted:
            return NSImage.statusNoneName
        case .inProgress:
            // eventually have a spinner instead
            return NSImage.statusPartiallyAvailableName
        case .done:
            return NSImage.statusAvailableName
        case .failed:
            return NSImage.statusUnavailableName
        }
    }
}
