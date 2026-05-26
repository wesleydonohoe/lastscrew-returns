import Foundation

struct ItemDetails: Codable, Hashable, Identifiable {
    var id: String { orderId }
    let orderId: String
    let sku: String
    let name: String
    let brand: String
    let imageAsset: String
    let retailPriceUsd: Double
    let customerPaidUsd: Double
    let assemblyTimeMinutes: Int
    let packagingDifficulty: String
    let dimensions: String
    let weightLbs: Double
    let category: String
    let deliveredAt: String
    let returnReason: String
    let status: String
    let lastScrewEligible: Bool
    let ineligibleReason: String?
    let estPayoutRange: PayoutRange?
}

struct PayoutRange: Codable, Hashable {
    let low: Int
    let high: Int
}

struct OrdersResponse: Codable {
    let user: UserSummary
    let items: [ItemDetails]
}

struct UserSummary: Codable, Hashable {
    let firstName: String
    let rewardsBalance: Double
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
    let toolCalls: [ToolCallTrace]?
}

/// What signals the pricing agent actually looked at, surfaced for audit.
struct ToolCallTrace: Codable, Hashable {
    let name: String
    // arguments / result are arbitrary JSON; decode as raw JSONValue.
    let arguments: JSONValue?
    let result: JSONValue?
}

/// Minimal JSON value so we can faithfully render whatever the tool returned
/// without a per-tool Codable for every shape.
enum JSONValue: Codable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        if let n = try? c.decode(Double.self) { self = .number(n); return }
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let a = try? c.decode([JSONValue].self) { self = .array(a); return }
        if let o = try? c.decode([String: JSONValue].self) { self = .object(o); return }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unknown JSON value")
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let b): try c.encode(b)
        case .number(let n): try c.encode(n)
        case .string(let s): try c.encode(s)
        case .array(let a): try c.encode(a)
        case .object(let o): try c.encode(o)
        }
    }

    /// Convenience accessor for `.object["key"]?.string` style reads.
    subscript(key: String) -> JSONValue? {
        if case .object(let o) = self { return o[key] }
        return nil
    }

    var stringValue: String? { if case .string(let s) = self { return s }; return nil }
    var numberValue: Double? { if case .number(let n) = self { return n }; return nil }
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
        name: "Sleep by Wayfair™ 12\" Memory Foam Mattress + Platform Bed",
        brand: "Sleep by Wayfair™",
        imageAsset: "MattressHero",
        retailPriceUsd: 549,
        customerPaidUsd: 489,
        assemblyTimeMinutes: 92,
        packagingDifficulty: "medium",
        dimensions: "Queen 63\"W x 83\"L x 18\"H",
        weightLbs: 142,
        category: "bedroom",
        deliveredAt: "2026-05-17",
        returnReason: "doesnt_fit",
        status: "delivered",
        lastScrewEligible: true,
        ineligibleReason: nil,
        estPayoutRange: PayoutRange(low: 120, high: 175)
    )

    static let demoFeed: [ItemDetails] = [
        ItemDetails(
            orderId: "WF-ORDER-8820",
            sku: "WF-HARLOW-TWN-WHT",
            name: "Harlow Solid Wood Platform Bed",
            brand: "Red Barrel Studio®",
            imageAsset: "HarlowBed",
            retailPriceUsd: 329, customerPaidUsd: 289,
            assemblyTimeMinutes: 68, packagingDifficulty: "medium",
            dimensions: "Twin 41\"W x 78\"L x 14\"H", weightLbs: 78,
            category: "bedroom", deliveredAt: "2026-05-26",
            returnReason: "doesnt_fit", status: "delivered",
            lastScrewEligible: true, ineligibleReason: nil,
            estPayoutRange: PayoutRange(low: 95, high: 145)
        ),
        .demo,
        ItemDetails(
            orderId: "WF-ORDER-8826",
            sku: "WF-LUCERA-TWN-WHT",
            name: "Lucera Mid-Century Bobbin Bed",
            brand: "August Grove®",
            imageAsset: "LuceraBed",
            retailPriceUsd: 419, customerPaidUsd: 369,
            assemblyTimeMinutes: 84, packagingDifficulty: "hard",
            dimensions: "Twin 42\"W x 80\"L x 36\"H", weightLbs: 96,
            category: "bedroom", deliveredAt: "2026-05-23",
            returnReason: "doesnt_fit", status: "delivered",
            lastScrewEligible: true, ineligibleReason: nil,
            estPayoutRange: PayoutRange(low: 130, high: 195)
        )
    ]
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
        source: "fallback",
        toolCalls: nil
    )
}
