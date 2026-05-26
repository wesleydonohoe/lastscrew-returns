import Foundation

struct ItemDetails: Codable, Hashable, Identifiable {
    var id: String { orderId }
    let orderId: String
    let sku: String
    let name: String
    let retailPriceUsd: Double
    let customerPaidUsd: Double
    let assemblyTimeMinutes: Int
    let packagingDifficulty: String
    let dimensions: String
    let weightLbs: Double
    let category: String
    let deliveredAt: String
    let returnReason: String
}

struct HostOffer: Codable, Hashable {
    let orderId: String
    let zip: String
    let signingBonusUsd: Int
    let dailyStorageUsd: Int
    let maxStorageDays: Int
    let resaleBountyUsd: Int
    let photoBonusUsd: Int
    let projectedMaxEarningsUsd: Int
    let expectedDaysToClaim: Int
    let reasoning: String
    let source: String
}

struct PackagingChecklistItem: Codable, Hashable, Identifiable {
    var id: String { label }
    let label: String
    let passed: Bool
    let detail: String?
}

struct PackagingQAResult: Codable, Hashable {
    let orderId: String?
    let verdict: String
    let score: Double
    let checklist: [PackagingChecklistItem]
    let notes: String
    let bonusMultiplier: Double
    let source: String

    var verdictColor: ColorToken {
        switch verdict {
        case "pass": return .green
        case "needs_work": return .amber
        default: return .red
        }
    }

    enum ColorToken { case green, amber, red }
}

/// Local fallback so previews + offline demo work without the worker running.
extension ItemDetails {
    static let demo = ItemDetails(
        orderId: "WF-ORDER-8821",
        sku: "WF-SLP-12MED-Q",
        name: "Sleep by Wayfair™ 12\" Medium Memory Foam Mattress + Platform Bed",
        retailPriceUsd: 549,
        customerPaidUsd: 489,
        assemblyTimeMinutes: 92,
        packagingDifficulty: "medium",
        dimensions: "Queen 63\"W x 83\"L x 18\"H",
        weightLbs: 142,
        category: "bedroom",
        deliveredAt: "2026-05-17",
        returnReason: "doesnt_fit"
    )
}

extension HostOffer {
    static let demo = HostOffer(
        orderId: "WF-ORDER-8821",
        zip: "02116",
        signingBonusUsd: 50,
        dailyStorageUsd: 3,
        maxStorageDays: 14,
        resaleBountyUsd: 90,
        photoBonusUsd: 15,
        projectedMaxEarningsUsd: 197,
        expectedDaysToClaim: 8,
        reasoning: "Local demand is strong (12 nearby shoppers, expected claim in 8 days). Skipping the return-shipping leg and warehouse intake saves Wayfair ~$285. We share ~70% of that with you.",
        source: "fallback"
    )
}
