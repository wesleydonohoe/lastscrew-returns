import SwiftUI

@main
struct LastscrewApp: App {
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .preferredColorScheme(.light)
                .tint(Theme.purple)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        NavigationStack(path: $router.path) {
            ManageItemView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .returnChooser(let item):
                        ReturnChooserView(item: item)
                    case .offerReveal(let item):
                        OfferRevealView(item: item)
                    case .acceptHost(let item, let offer):
                        AcceptHostView(item: item, offer: offer)
                    case .packagingCamera(let item, let offer):
                        PackagingCameraView(item: item, offer: offer)
                    case .packagingResult(let item, let offer, let qa):
                        PackagingResultView(item: item, offer: offer, qa: qa)
                    case .hostDashboard(let item, let offer, let qa):
                        HostDashboardView(item: item, offer: offer, qa: qa)
                    }
                }
        }
    }
}
