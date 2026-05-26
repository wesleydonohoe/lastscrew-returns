import SwiftUI

struct EarningsBreakdownView: View {
    let offer: HostOffer

    private var components: [(String, Int, Color, String)] {
        [
            ("Signing bonus",                offer.signingBonusUsd,                          Theme.molten,    "Hits your account the moment you accept."),
            ("Dismantle + pack labor",       offer.photoBonusUsd,                            Theme.amber,     "Paid when our vision model confirms the package is ship-ready."),
            ("Storage rent × \(offer.maxStorageDays)d", offer.dailyStorageUsd * offer.maxStorageDays, Theme.chromeDim, "Up to $\(offer.dailyStorageUsd)/day while it sits in your home."),
            ("Resale bounty",                offer.resaleBountyUsd,                          Theme.acid,      "Paid when a local buyer claims the assembled-deal listing.")
        ]
    }

    private var total: Int { components.map(\.1).reduce(0, +) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How you earn")
                .font(.headline)
                .foregroundStyle(Theme.text)
            stackedBar
            VStack(spacing: 12) {
                ForEach(components, id: \.0) { (label, amount, color, blurb) in
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 4).fill(color).frame(width: 8, height: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                            Text(blurb).font(.caption).foregroundStyle(Theme.textMuted)
                        }
                        Spacer()
                        Text("$\(amount)")
                            .font(Theme.moneyFont)
                            .foregroundStyle(Theme.money)
                    }
                }
            }
        }
        .cardStyle()
    }

    private var stackedBar: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                ForEach(components, id: \.0) { (_, amount, color, _) in
                    color
                        .frame(width: max(2, geo.size.width * CGFloat(amount) / CGFloat(max(total, 1))))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .frame(height: 14)
    }
}
