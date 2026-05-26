import SwiftUI

struct OfferRevealView: View {
    @EnvironmentObject var router: AppRouter
    let item: ItemDetails
    @StateObject private var vm = OfferViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                heroNumber

                if vm.isLoading {
                    skeleton
                } else if let offer = vm.offer {
                    EarningsBreakdownView(offer: offer)
                    reasoningCard(offer)
                    sourceTag(offer)
                }

                Spacer(minLength: 80)
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if let offer = vm.offer {
                acceptCTA(offer: offer)
            }
        }
        .navigationTitle("Your Offer")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(orderId: item.orderId) }
    }

    private var heroNumber: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dismantle it. Earn up to")
                .font(Theme.headingFont)
                .foregroundStyle(Theme.text)
            ZStack {
                Theme.heatHalo.frame(height: 60).blendMode(.plusLighter)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("$")
                        .font(.system(size: 28, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.money)
                    Text("\(vm.offer?.projectedMaxEarningsUsd ?? 0)")
                        .font(Theme.bigMoneyFont)
                        .foregroundStyle(Theme.money)
                        .contentTransition(.numericText(value: Double(vm.offer?.projectedMaxEarningsUsd ?? 0)))
                    Spacer()
                }
            }
            Text("for the work you'd be doing anyway. On top of your full refund.")
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
        }
    }

    private var skeleton: some View {
        VStack(spacing: 12) {
            ForEach(0..<4) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.border, lineWidth: 1)
                    )
                    .frame(height: 72)
            }
        }
    }

    private func reasoningCard(_ offer: HostOffer) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Theme.accent)
                Text("Why this offer")
                    .font(.headline)
                    .foregroundStyle(Theme.text)
            }
            Text(offer.reasoning)
                .font(.subheadline)
                .foregroundStyle(Theme.text.opacity(0.85))
        }
        .cardStyle()
    }

    private func sourceTag(_ offer: HostOffer) -> some View {
        HStack {
            Spacer()
            Text(offer.source == "subconscious" ? "Priced by Subconscious agent" : "Priced by fallback model")
                .font(.caption)
                .foregroundStyle(Theme.textFaint)
        }
    }

    private func acceptCTA(offer: HostOffer) -> some View {
        Button {
            router.push(.acceptHost(item, offer))
        } label: {
            HStack {
                Text("Accept · $\(offer.signingBonusUsd) today")
                    .font(.headline)
                Spacer()
                Image(systemName: "arrow.right")
            }
            .padding(.vertical, 16).padding(.horizontal, 20)
            .foregroundColor(Theme.gunmetal)
            .background(Theme.earnGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Theme.molten.opacity(0.5), radius: 18, y: 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
