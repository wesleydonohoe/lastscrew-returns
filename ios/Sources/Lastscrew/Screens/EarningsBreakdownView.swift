import SwiftUI

struct EarningsBreakdownView: View {
    let offer: HostOffer

    private var components: [(String, Int, Color, String)] {
        [
            ("Signing bonus", offer.signingBonusUsd, Theme.purple, "Hits your account when you accept."),
            ("Daily storage × \(offer.maxStorageDays)d", offer.dailyStorageUsd * offer.maxStorageDays, Color(red: 0.55, green: 0.30, blue: 0.85), "Up to $\(offer.dailyStorageUsd)/day while it sits."),
            ("Resale bounty", offer.resaleBountyUsd, Theme.green, "Paid when a local buyer claims it."),
            ("Photo verification bonus", offer.photoBonusUsd, Color(red: 0.95, green: 0.6, blue: 0.15), "After packaging QA passes.")
        ]
    }

    private var total: Int { components.map(\.1).reduce(0, +) }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How you earn")
                .font(.headline)
            stackedBar
            VStack(spacing: 12) {
                ForEach(components, id: \.0) { (label, amount, color, blurb) in
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 4).fill(color).frame(width: 8, height: 36)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(label).font(.subheadline.weight(.semibold))
                            Text(blurb).font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                        Text("$\(amount)")
                            .font(Theme.moneyFont)
                            .foregroundStyle(color)
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
