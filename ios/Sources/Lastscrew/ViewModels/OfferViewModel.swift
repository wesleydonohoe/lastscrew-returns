import Foundation

@MainActor
final class OfferViewModel: ObservableObject {
    @Published var offer: HostOffer?
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// Staged steps that mirror the ReAct agent's tool calls — surfaced so the
    /// user can watch the pricing brain work.
    @Published var steps: [AgentStep] = AgentStep.defaultPricingPlan
    @Published var streamComplete = false

    func load(orderId: String, zip: String = "02116") async {
        isLoading = true
        errorMessage = nil
        streamComplete = false
        steps = AgentStep.defaultPricingPlan
        defer { isLoading = false }

        // Kick off the real API call in parallel with the step animation.
        async let liveOffer: HostOffer? = fetchOffer(orderId: orderId, zip: zip)
        let offer = await liveOffer
        await playStream(usingOffer: offer)
    }

    private func fetchOffer(orderId: String, zip: String) async -> HostOffer? {
        do {
            return try await APIClient.shared.requestOffer(orderId: orderId, zip: zip)
        } catch {
            self.errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            return .demo
        }
    }

    private func playStream(usingOffer offer: HostOffer?) async {
        for i in steps.indices {
            steps[i].state = .running
            try? await Task.sleep(nanoseconds: 950_000_000)
            if let toolName = steps[i].toolName,
               let tc = offer?.toolCalls?.first(where: { $0.name == toolName }) {
                steps[i].resultSummary = OfferViewModel.summarize(tc)
            }
            steps[i].state = .done
        }
        self.offer = offer
        try? await Task.sleep(nanoseconds: 350_000_000)
        streamComplete = true
    }

    static func summarize(_ tc: ToolCallTrace) -> String {
        guard let result = tc.result else { return "" }
        switch tc.name {
        case "get_item_details":
            let name = result["name"]?.stringValue ?? "item"
            let weight = result["weightLbs"]?.numberValue.map { "\(Int($0)) lb" } ?? ""
            let price = result["retailPriceUsd"]?.numberValue.map { "$\(Int($0)) retail" } ?? ""
            let diff = result["packagingDifficulty"]?.stringValue.map { "\($0) pkg" } ?? ""
            return [name.split(separator: " ").prefix(4).joined(separator: " "),
                    weight, price, diff]
                .filter { !$0.isEmpty }.joined(separator: " · ")
        case "get_local_demand":
            let shoppers = result["interestedShoppers"]?.numberValue.map { "\(Int($0))" } ?? "?"
            let days = result["expectedDaysToClaim"]?.numberValue.map { "\(Int($0))d" } ?? "?"
            return "\(shoppers) shoppers · expected \(days) claim"
        case "get_warehouse_pressure":
            let util = result["fcUtilizationPct"]?.numberValue.map { "\(Int($0))% FC" } ?? "?"
            let saved = result["savedIfHostShipsDirect"]?.numberValue.map { "$\(Int($0)) saved" } ?? "?"
            return "\(util) · \(saved)"
        default:
            return ""
        }
    }
}

struct AgentStep: Identifiable, Hashable {
    enum State: Hashable { case pending, running, done }
    let id = UUID()
    let title: String
    let toolName: String?
    var state: State = .pending
    var resultSummary: String = ""

    static let defaultPricingPlan: [AgentStep] = [
        AgentStep(title: "Looking up your item",            toolName: "get_item_details"),
        AgentStep(title: "Checking local demand",           toolName: "get_local_demand"),
        AgentStep(title: "Pulling FC pressure + savings",   toolName: "get_warehouse_pressure"),
        AgentStep(title: "Composing your offer",            toolName: nil),
    ]
}
