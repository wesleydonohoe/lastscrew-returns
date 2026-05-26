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
                    Text("\(item.assemblyTimeMinutes) min to assemble · \(Int(item.weightLbs)) lb")
                        .font(.subheadline)
                        .foregroundStyle(Theme.muted)
                }

                standardCard
                lastScrewCard

                Text("Last Screw is Wayfair's micro-warehouse program. You keep the item assembled at home, photograph the package, and earn while it waits for a local buyer.")
                    .font(.footnote)
                    .foregroundStyle(Theme.muted)
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
                Spacer()
                Text("$0 extra").font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.muted)
            }
            row(symbol: "arrow.uturn.backward.circle", text: "100% refund to your card")
            row(symbol: "wrench.and.screwdriver.fill", text: "Disassemble the item (~\(item.assemblyTimeMinutes) min)", warning: true)
            row(symbol: "shippingbox", text: "Re-box and schedule pickup", warning: true)
            row(symbol: "clock", text: "Refund posts in 5–7 days")
            Button {
                // not implemented for v1
            } label: {
                Text("Choose standard")
                    .font(.headline)
                    .foregroundColor(Theme.text)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.cardStroke, lineWidth: 1)
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
                        .foregroundColor(.white)
                    Text("Last Screw return")
                        .font(Theme.headingFont)
                        .foregroundColor(.white)
                }
                Spacer()
                Text("EARN")
                    .font(.caption.weight(.heavy))
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.white)
                    .foregroundColor(Theme.purple)
                    .clipShape(Capsule())
            }
            row(symbol: "checkmark.circle.fill", text: "100% refund — same as standard", inverted: true)
            row(symbol: "bed.double.fill", text: "Keep the item ASSEMBLED in your home", inverted: true, highlight: true)
            row(symbol: "shippingbox.fill", text: "Just wrap & photograph the package", inverted: true)
            row(symbol: "dollarsign.circle.fill", text: "Earn signing bonus + storage + bounty", inverted: true, highlight: true)

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
                .foregroundColor(Theme.purpleDeep)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(20)
        .background(Theme.earnGradient)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Theme.purple.opacity(0.3), radius: 20, y: 10)
    }

    private func row(symbol: String, text: String, warning: Bool = false, inverted: Bool = false, highlight: Bool = false) -> some View {
        HStack(spacing: 10) {
            Image(systemName: symbol)
                .foregroundColor(
                    inverted ? .white : (warning ? Theme.red : Theme.purple)
                )
                .frame(width: 22)
            Text(text)
                .font(.subheadline.weight(highlight ? .semibold : .regular))
                .foregroundColor(inverted ? .white : Theme.text)
            Spacer()
        }
    }
}
