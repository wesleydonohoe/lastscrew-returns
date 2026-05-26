import SwiftUI

enum AppRoute: Hashable {
    case manageItem(ItemDetails)
    case returnChooser(ItemDetails)
    case offerReveal(ItemDetails)
    case acceptHost(ItemDetails, HostOffer)
    case packagingCamera(ItemDetails, HostOffer, [String])
    case packagingResult(ItemDetails, HostOffer, PackagingQAResult)
    case hostDashboard(ItemDetails, HostOffer, PackagingQAResult)
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var path: [AppRoute] = []

    func push(_ route: AppRoute) { path.append(route) }
    func popToRoot() { path.removeAll() }
}
