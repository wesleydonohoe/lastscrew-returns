import SwiftUI

struct ReturnChooserView: View {
    @EnvironmentObject var router: AppRouter
    let item: ItemDetails

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Choose how to return")
                        .font(Theme.titleFont)
                        .foregroundStyle(Theme.text)
                    Text("\(item.assemblyTimeMinutes) min to assemble · \(Int(item.weightLbs)) lb")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMuted)
                }

                standardCard
                lastScrewCard

                Text("Last Screw is Wayfair's micro-warehouse program. You do the same dismantling and repackaging the warehouse would do — except you get paid for the work, plus a bounty when a neighbor claims the item at a discount.")
                    .font(.footnote)
                    .foregroundStyle(Theme.textMuted)
                    .padding(.top, 8)
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Return")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var standardCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Standard return")
                    .font(Theme.headingFont)
                    .foregroundStyle(Theme.text)
                Spacer()
                Text("$0 extra")
                    .font(Theme.monoFont)
                    .foregroundStyle(Theme.textMuted)
            }
            row(symbol: "arrow.uturn.backward.circle", text: "100% refund to your card")
            row(symbol: "wrench.and.screwdriver.fill", text: "Dismantle the item yourself (~\(item.assemblyTimeMinutes) min)", warning: true)
            row(symbol: "shippingbox", text: "Re-box and schedule pickup", warning: true)
            row(symbol: "dollarsign.slash", text: "$0 for the labor — Wayfair pays the warehouse to do it instead", warning: true)
            row(symbol: "clock", text: "Refund posts in 5–7 days")
            Button {
                // not implemented for v1
            } label: {
                Text("Choose standard")
                    .font(.headline)
                    .foregroundColor(Theme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Theme.surfaceRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .cardStyle()
    }

    private var lastScrewCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(Theme.chrome)
                    Text("Last Screw return")
                        .font(Theme.headingFont)
                        .foregroundColor(Theme.chrome)
                }
                Spacer()
                Text("EARN")
                    .font(.caption.weight(.heavy))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Theme.chrome)
                    .foregroundColor(Theme.gunmetal)
                    .clipShape(Capsule())
            }
            row(symbol: "checkmark.circle.fill", text: "100% refund — same as standard", inverted: true)
            row(symbol: "wrench.and.screwdriver.fill", text: "You still dismantle — but now you get PAID for it", inverted: true, highlight: true)
            row(symbol: "shippingbox.fill", text: "Repackage, photograph, hold as a local node", inverted: true)
            row(symbol: "dollarsign.circle.fill", text: "Signing bonus + dismantle labor + bounty when a neighbor claims it", inverted: true, highlight: true)

            Button {
                router.push(.offerReveal(item))
            } label: {
                HStack {
                    Text("See my offer")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding(.vertical, 14).padding(.horizontal, 18)
                .foregroundColor(Theme.gunmetal)
                .background(Theme.chrome)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(20)
        .background(Theme.earnGradient)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Theme.molten.opacity(0.5), radius: 22, y: 10)
    }

    private func row(symbol: String, text: String, warning: Bool = false, inverted: Bool = false, highlight: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundColor(
                    inverted ? Theme.chrome : (warning ? Theme.danger : Theme.accent)
                )
                .frame(width: 22)
            Text(text)
                .font(.subheadline.weight(highlight ? .semibold : .regular))
                .foregroundColor(inverted ? Theme.chrome : Theme.text)
            Spacer()
        }
    }
}
