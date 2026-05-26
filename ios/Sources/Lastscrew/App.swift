import SwiftUI

@main
struct LastscrewApp: App {
    @StateObject private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(router)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var router: AppRouter

    var body: some View {
        NavigationStack(path: $router.path) {
            HomeView()
                .navigationDestination(for: AppRoute.self) { route in
                    switch route {
                    case .manageItem(let item):
                        ManageItemView(item: item)
                    case .returnChooser(let item):
                        ReturnChooserView(item: item)
                    case .offerReveal(let item):
                        OfferRevealView(item: item)
                    case .acceptHost(let item, let offer):
                        AcceptHostView(item: item, offer: offer)
                    case .packagingCamera(let item, let offer, let tips):
                        PackagingCameraView(item: item, offer: offer, retakeTips: tips)
                    case .packagingResult(let item, let offer, let qa):
                        PackagingResultView(item: item, offer: offer, qa: qa)
                    case .hostDashboard(let item, let offer, let qa):
                        HostDashboardView(item: item, offer: offer, qa: qa)
                    }
                }
        }
    }
}
