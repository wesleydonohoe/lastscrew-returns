import SwiftUI

struct OfferRevealView: View {
    @EnvironmentObject var router: AppRouter
    let item: ItemDetails
    @StateObject private var vm = OfferViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if vm.streamComplete, let offer = vm.offer {
                    heroNumber(offer: offer)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    EarningsBreakdownView(offer: offer)
                        .transition(.opacity)
                    reasoningCard(offer)
                        .transition(.opacity)
                    sourceTag(offer)
                } else {
                    AgentStreamPanel(steps: vm.steps, itemName: item.name)
                        .transition(.opacity)
                }
                Spacer(minLength: 80)
            }
            .padding(20)
            .animation(.easeInOut(duration: 0.4), value: vm.streamComplete)
        }
        .background(Theme.bg.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            if vm.streamComplete, let offer = vm.offer {
                acceptCTA(offer: offer)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationTitle("Your Offer")
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load(orderId: item.orderId) }
    }

    private func heroNumber(offer: HostOffer) -> some View {
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
                    Text("\(offer.projectedMaxEarningsUsd)")
                        .font(Theme.bigMoneyFont)
                        .foregroundStyle(Theme.money)
                        .contentTransition(.numericText(value: Double(offer.projectedMaxEarningsUsd)))
                    Spacer()
                }
            }
            Text("for the work you'd be doing anyway. On top of your full refund.")
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
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

// MARK: - Agent reasoning stream

struct AgentStreamPanel: View {
    let steps: [AgentStep]
    let itemName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                AgentSpinner()
                Text("PRICING AGENT")
                    .font(.caption.weight(.heavy))
                    .tracking(2)
                    .foregroundStyle(Theme.molten)
                Spacer()
                Text("subconscious")
                    .font(Theme.monoFont)
                    .foregroundStyle(Theme.textFaint)
            }
            Text("Reasoning over \(itemName.split(separator: " ").prefix(5).joined(separator: " "))…")
                .font(Theme.monoFont)
                .foregroundStyle(Theme.textMuted)

            Divider().background(Theme.border)

            VStack(alignment: .leading, spacing: 14) {
                ForEach(steps) { step in
                    AgentStepRow(step: step)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .leading)),
                            removal: .opacity
                        ))
                }
            }
            .animation(.easeOut(duration: 0.3), value: steps.map(\.state))
        }
        .padding(18)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.molten.opacity(0.35), lineWidth: 1)
        )
    }
}

private struct AgentStepRow: View {
    let step: AgentStep

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            stateIcon
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.system(size: 14, weight: step.state == .running ? .heavy : .semibold, design: .default))
                    .foregroundStyle(step.state == .pending ? Theme.textFaint : Theme.text)
                if !step.resultSummary.isEmpty, step.state == .done {
                    Text(step.resultSummary)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundStyle(Theme.acid.opacity(0.95))
                        .transition(.opacity)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var stateIcon: some View {
        switch step.state {
        case .pending:
            Circle()
                .stroke(Theme.textFaint, lineWidth: 1.5)
                .frame(width: 14, height: 14)
        case .running:
            AgentSpinner()
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.acid)
                .font(.system(size: 16))
        }
    }
}

private struct AgentSpinner: View {
    @State private var rotation: Double = 0
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(Theme.molten, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: 14, height: 14)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
