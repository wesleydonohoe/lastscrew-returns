import Foundation

@MainActor
final class OfferViewModel: ObservableObject {
    @Published var offer: HostOffer?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(orderId: String, zip: String = "02116") async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            self.offer = try await APIClient.shared.requestOffer(orderId: orderId, zip: zip)
        } catch {
            self.errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            // Worker not running? Fall back to a believable local offer so the demo still flows.
            self.offer = .demo
        }
    }
}
