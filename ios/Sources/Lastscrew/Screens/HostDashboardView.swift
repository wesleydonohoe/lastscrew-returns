import SwiftUI

struct HostDashboardView: View {
    @EnvironmentObject var router: AppRouter
    let item: ItemDetails
    let offer: HostOffer
    let qa: PackagingQAResult

    @State private var startDate = Date()
    @State private var now = Date()
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                summaryHeader
                earningsTickerCard
                statusCard
                ctaRow
                Button {
                    router.popToRoot()
                } label: {
                    Text("Done — return to home")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Host dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(ticker) { now = $0 }
    }

    private var elapsedSeconds: Double {
        max(0, now.timeIntervalSince(startDate))
    }

    private var liveEarnings: Double {
        let perSecond = Double(offer.dailyStorageUsd) / 86_400.0
        return Double(offer.signingBonusUsd) + perSecond * elapsedSeconds
    }

    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.name)
                .font(.headline)
            Text("ZIP \(offer.zip) · Expected claim in \(offer.expectedDaysToClaim) days")
                .font(.subheadline)
                .foregroundStyle(Theme.muted)
        }
    }

    private var earningsTickerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Earned so far").font(.subheadline).foregroundStyle(Theme.muted)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("$")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.purple)
                Text(String(format: "%.4f", liveEarnings))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.purpleDeep)
                    .contentTransition(.numericText(value: liveEarnings))
                    .animation(.easeOut(duration: 0.2), value: liveEarnings)
            }
            HStack(spacing: 10) {
                Label("$\(offer.dailyStorageUsd)/day storage", systemImage: "clock.fill")
                    .font(.caption).foregroundStyle(Theme.muted)
                Label("Bonus \(String(format: "%.2f×", qa.bonusMultiplier))", systemImage: "star.fill")
                    .font(.caption).foregroundStyle(Theme.muted)
            }
            Text("Up to $\(offer.projectedMaxEarningsUsd) total")
                .font(.footnote)
                .foregroundStyle(Theme.green)
        }
        .cardStyle()
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            statusRow(.green, icon: "shippingbox.fill", title: "Packaged & QA'd", subtitle: "Score \(Int(qa.score * 100))%")
            statusRow(.orange, icon: "magnifyingglass", title: "Listed for local buyers", subtitle: "ETA \(offer.expectedDaysToClaim) days")
            statusRow(.gray, icon: "truck.box.fill", title: "Awaiting carrier handoff", subtitle: "We'll notify you when a buyer claims it")
        }
        .cardStyle()
    }

    private func statusRow(_ color: Color, icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.18)).frame(width: 32, height: 32)
                Image(systemName: icon).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(Theme.muted)
            }
            Spacer()
        }
    }

    private var ctaRow: some View {
        HStack(spacing: 12) {
            actionPill(title: "Schedule pickup", icon: "calendar")
            actionPill(title: "Notify me", icon: "bell.fill")
        }
    }

    private func actionPill(title: String, icon: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.purple.opacity(0.08))
            .foregroundColor(Theme.purple)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
