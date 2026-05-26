import SwiftUI

struct HomeView: View {
    @EnvironmentObject var router: AppRouter
    @State private var user: UserSummary = UserSummary(firstName: "Wes", rewardsBalance: 95.04)
    @State private var items: [ItemDetails] = ItemDetails.demoFeed
    @State private var loaded = false

    private var eligible: [ItemDetails] { items.filter(\.lastScrewEligible) }
    private var ineligible: [ItemDetails] { items.filter { !$0.lastScrewEligible } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                greetingBlock
                rewardsBlock

                if !eligible.isEmpty {
                    eligibleHeader
                    ForEach(eligible) { item in
                        Button { router.push(.manageItem(item)) } label: {
                            EligibleRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !ineligible.isEmpty {
                    Text("Other orders")
                        .font(Theme.headingFont)
                        .foregroundStyle(Theme.textMuted)
                        .padding(.top, 8)
                    ForEach(ineligible) { item in
                        Button { router.push(.manageItem(item)) } label: {
                            IneligibleRow(item: item)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("LASTSCREW")
                    .font(.system(size: 16, weight: .heavy, design: .default))
                    .tracking(2)
                    .foregroundStyle(Theme.text)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Image(systemName: "person.crop.circle")
                    .foregroundStyle(Theme.textMuted)
            }
        }
        .task { await load() }
    }

    private var greetingBlock: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hi \(user.firstName)")
                .font(Theme.titleFont)
                .foregroundStyle(Theme.text)
            Text("\(items.count) orders · \(eligible.count) eligible for Last Screw")
                .font(.subheadline)
                .foregroundStyle(Theme.textMuted)
        }
    }

    private var rewardsBlock: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Total Rewards Earned this year")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("$")
                        .font(.system(size: 16, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.money)
                    Text(String(format: "%.2f", user.rewardsBalance))
                        .font(.system(size: 24, weight: .heavy, design: .monospaced))
                        .foregroundStyle(Theme.money)
                }
            }
            Spacer()
            Image(systemName: "arrow.right")
                .foregroundStyle(Theme.textMuted)
        }
        .cardStyle()
    }

    private var eligibleHeader: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(Theme.molten.opacity(0.2)).frame(width: 24, height: 24)
                Image(systemName: "sparkles")
                    .font(.caption2.weight(.heavy))
                    .foregroundColor(Theme.molten)
            }
            Text("Earn from your returns")
                .font(Theme.headingFont)
                .foregroundStyle(Theme.text)
            Text("\(eligible.count)")
                .font(Theme.monoFont)
                .foregroundColor(Theme.molten)
            Spacer()
        }
        .padding(.top, 4)
    }

    private func load() async {
        guard !loaded else { return }
        loaded = true
        do {
            let resp = try await APIClient.shared.fetchOrders()
            self.user = resp.user
            self.items = resp.items
        } catch {
            // keep .demoFeed
        }
    }
}

// MARK: - Eligible row

private struct EligibleRow: View {
    let item: ItemDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // top row: image + name + chevron
            HStack(alignment: .top, spacing: 14) {
                Image(item.imageAsset)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    )

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        statusChip(label: "Delivered", color: Theme.money)
                        statusChip(label: "ELIGIBLE", color: Theme.molten, glow: true)
                    }
                    Text(item.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Theme.text)
                        .lineLimit(2)
                    Text("By \(item.brand) · \(Int(item.weightLbs)) lb · \(item.assemblyTimeMinutes) min")
                        .font(.caption)
                        .foregroundStyle(Theme.textMuted)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.right")
                    .foregroundStyle(Theme.textMuted)
            }

            // payout band
            if let range = item.estPayoutRange {
                Divider().background(Theme.border).padding(.vertical, 12)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Est. payout")
                            .font(.caption2)
                            .foregroundStyle(Theme.textFaint)
                            .tracking(1)
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("$")
                                .font(.system(size: 14, weight: .heavy, design: .monospaced))
                                .foregroundStyle(Theme.money)
                            Text("\(range.low)")
                                .font(.system(size: 20, weight: .heavy, design: .monospaced))
                                .foregroundStyle(Theme.money)
                            Text("–")
                                .font(.system(size: 16, weight: .heavy, design: .monospaced))
                                .foregroundStyle(Theme.textMuted)
                                .padding(.horizontal, 2)
                            Text("$")
                                .font(.system(size: 14, weight: .heavy, design: .monospaced))
                                .foregroundStyle(Theme.money)
                            Text("\(range.high)")
                                .font(.system(size: 20, weight: .heavy, design: .monospaced))
                                .foregroundStyle(Theme.money)
                        }
                    }
                    Spacer()
                    Text("See offer →")
                        .font(.caption.weight(.heavy))
                        .tracking(1)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Theme.molten.opacity(0.15))
                        .foregroundColor(Theme.molten)
                        .overlay(Capsule().stroke(Theme.molten.opacity(0.5), lineWidth: 1))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Theme.molten.opacity(0.4), lineWidth: 1)
        )
        .shadow(color: Theme.molten.opacity(0.1), radius: 12, y: 4)
    }
}

// MARK: - Ineligible row (dimmer)

private struct IneligibleRow: View {
    let item: ItemDetails

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(item.imageAsset)
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1)
                )
                .opacity(0.85)
            VStack(alignment: .leading, spacing: 4) {
                statusChip(label: "Delivered", color: Theme.chromeDim)
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.textMuted)
                    .lineLimit(2)
                if let reason = item.ineligibleReason {
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                            .foregroundColor(Theme.textFaint)
                        Text(reason)
                            .font(.caption2)
                            .foregroundStyle(Theme.textFaint)
                            .lineLimit(2)
                    }
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.textFaint)
        }
        .padding(14)
        .background(Theme.surface.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Theme.border.opacity(0.6), lineWidth: 1)
        )
    }
}

@ViewBuilder
private func statusChip(label: String, color: Color, glow: Bool = false) -> some View {
    Text(label)
        .font(.caption2.weight(.heavy))
        .tracking(1)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(glow ? 0.22 : 0.15))
        .foregroundColor(color)
        .overlay(Capsule().stroke(color.opacity(0.5), lineWidth: 1))
        .clipShape(Capsule())
}
