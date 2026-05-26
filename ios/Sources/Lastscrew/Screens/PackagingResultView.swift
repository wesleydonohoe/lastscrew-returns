import SwiftUI

struct PackagingResultView: View {
    @EnvironmentObject var router: AppRouter
    let item: ItemDetails
    let offer: HostOffer
    let qa: PackagingQAResult

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                verdictHero
                checklistCard
                bonusCard
                notesCard

                if qa.verdict == "pass" {
                    primaryCTA
                } else {
                    HStack(spacing: 12) {
                        retryButton
                        if qa.verdict == "needs_work" { proceedAnywayButton }
                    }
                }
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Packaging review")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var verdictHero: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(verdictBackground).frame(width: 80, height: 80)
                Image(systemName: verdictIcon)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(verdictTitle).font(Theme.titleFont)
                Text(verdictSubtitle).font(.subheadline).foregroundStyle(Theme.muted)
                Text(qa.source == "baseten" ? "Verified by Baseten model" : "Verified by mock QA")
                    .font(.caption).foregroundStyle(Theme.muted.opacity(0.8))
            }
            Spacer()
        }
        .cardStyle()
    }

    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Checklist").font(.headline)
            ForEach(qa.checklist) { c in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: c.passed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(c.passed ? Theme.green : Color.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.label).font(.subheadline.weight(.semibold))
                        if let d = c.detail, !d.isEmpty {
                            Text(d).font(.caption).foregroundStyle(Theme.muted)
                        }
                    }
                    Spacer()
                }
            }
        }
        .cardStyle()
    }

    private var bonusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Bonus multiplier").font(.headline)
                Spacer()
                Text(String(format: "%.2f×", qa.bonusMultiplier))
                    .font(Theme.moneyFont)
                    .foregroundStyle(qa.bonusMultiplier >= 1 ? Theme.green : Theme.red)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.93))
                    RoundedRectangle(cornerRadius: 8)
                        .fill(qa.bonusMultiplier >= 1 ? Theme.green : Theme.red)
                        .frame(width: geo.size.width * CGFloat(min(qa.bonusMultiplier / 1.2, 1.0)))
                }
            }.frame(height: 10)
            Text("Adjusted resale bounty: $\(adjustedBounty)")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(Theme.purpleDeep)
        }
        .cardStyle()
    }

    private var adjustedBounty: Int {
        Int(Double(offer.resaleBountyUsd) * qa.bonusMultiplier)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Inspector notes").font(.headline)
            Text(qa.notes).font(.subheadline).foregroundStyle(Theme.text.opacity(0.85))
        }
        .cardStyle()
    }

    private var primaryCTA: some View {
        Button {
            router.push(.hostDashboard(item, offer, qa))
        } label: {
            HStack {
                Text("Hand off to carrier").font(.headline)
                Spacer()
                Image(systemName: "arrow.right")
            }
            .padding(.vertical, 16).padding(.horizontal, 20)
            .foregroundColor(.white)
            .background(Theme.earnGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private var retryButton: some View {
        Button {
            router.path.removeLast()  // back to camera
        } label: {
            HStack { Image(systemName: "arrow.clockwise"); Text("Re-shoot") }
                .frame(maxWidth: .infinity)
                .font(.headline).foregroundColor(Theme.text)
                .padding(.vertical, 14)
                .background(Color.white)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.cardStroke))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var proceedAnywayButton: some View {
        Button {
            router.push(.hostDashboard(item, offer, qa))
        } label: {
            HStack { Text("Proceed anyway"); Image(systemName: "arrow.right") }
                .frame(maxWidth: .infinity)
                .font(.headline).foregroundColor(.white)
                .padding(.vertical, 14)
                .background(Theme.purple)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var verdictBackground: Color {
        switch qa.verdict {
        case "pass": return Theme.green
        case "needs_work": return Color.orange
        default: return Theme.red
        }
    }
    private var verdictIcon: String {
        switch qa.verdict {
        case "pass": return "checkmark"
        case "needs_work": return "exclamationmark"
        default: return "xmark"
        }
    }
    private var verdictTitle: String {
        switch qa.verdict {
        case "pass": return "Ship-ready"
        case "needs_work": return "Almost there"
        default: return "Not ready yet"
        }
    }
    private var verdictSubtitle: String {
        "Score: \(Int(qa.score * 100))%"
    }
}
