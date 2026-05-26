import SwiftUI

enum AppRoute: Hashable {
    case manageItem(ItemDetails)
    case returnChooser(ItemDetails)
    case offerReveal(ItemDetails)
    case acceptHost(ItemDetails, HostOffer)
    case packagingCamera(ItemDetails, HostOffer)
    case packagingResult(ItemDetails, HostOffer, PackagingQAResult)
    case hostDashboard(ItemDetails, HostOffer, PackagingQAResult)
}

@MainActor
final class AppRouter: ObservableObject {
    @Published var path: [AppRoute] = []
    /// Retake tips surfaced from a failed packaging QA verdict. The
    /// PackagingCameraView observes this and shows the coach overlay when
    /// non-empty. Passing via router lets us pop back to the existing camera
    /// view (keeping its AVCaptureSession alive) instead of pushing a new one.
    @Published var retakeTips: [String] = []

    func push(_ route: AppRoute) { path.append(route) }
    func popToRoot() { path.removeAll() }
}
