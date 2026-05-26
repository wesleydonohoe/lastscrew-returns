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
            Text("Keep it. Earn up to")
                .font(Theme.headingFont)
                .foregroundStyle(Theme.text)
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text("$")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.purple)
                Text("\(vm.offer?.projectedMaxEarningsUsd ?? 0)")
                    .font(Theme.bigMoneyFont)
                    .foregroundStyle(Theme.purpleDeep)
                    .contentTransition(.numericText(value: Double(vm.offer?.projectedMaxEarningsUsd ?? 0)))
            }
            Text("on top of your full refund — for \(item.name).")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
        }
    }

    private var skeleton: some View {
        VStack(spacing: 12) {
            ForEach(0..<4) { _ in
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(white: 0.93))
                    .frame(height: 72)
            }
        }
    }

    private func reasoningCard(_ offer: HostOffer) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(Theme.purple)
                Text("Why this offer")
                    .font(.headline)
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
                .foregroundStyle(Theme.muted)
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
            .foregroundColor(.white)
            .background(Theme.earnGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Theme.purple.opacity(0.3), radius: 14, y: 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
