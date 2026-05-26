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

                if qa.verdict != "pass" {
                    howToFixSection
                }

                if qa.verdict == "pass" {
                    primaryCTA
                } else {
                    HStack(spacing: 12) {
                        retakeWithTipsButton
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
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(Theme.gunmetal)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(verdictTitle).font(Theme.titleFont).foregroundStyle(Theme.text)
                Text(verdictSubtitle).font(Theme.monoFont).foregroundStyle(Theme.textMuted)
                Text(qa.source == "baseten" ? "Verified by Baseten model" : "Verified by mock QA")
                    .font(.caption).foregroundStyle(Theme.textFaint)
            }
            Spacer()
        }
        .cardStyle()
    }

    private var checklistCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Checklist").font(.headline).foregroundStyle(Theme.text)
            ForEach(qa.checklist) { c in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: c.passed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(c.passed ? Theme.money : Theme.warning)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(c.label).font(.subheadline.weight(.semibold)).foregroundStyle(Theme.text)
                        if let d = c.detail, !d.isEmpty {
                            Text(d).font(.caption).foregroundStyle(Theme.textMuted)
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
                Text("Bonus multiplier").font(.headline).foregroundStyle(Theme.text)
                Spacer()
                Text(String(format: "%.2f×", qa.bonusMultiplier))
                    .font(Theme.moneyFont)
                    .foregroundStyle(qa.bonusMultiplier >= 1 ? Theme.money : Theme.danger)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8).fill(Theme.surfaceRaised)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(qa.bonusMultiplier >= 1 ? Theme.money : Theme.danger)
                        .frame(width: geo.size.width * CGFloat(min(qa.bonusMultiplier / 1.2, 1.0)))
                }
            }.frame(height: 10)
            Text("Adjusted resale bounty: $\(adjustedBounty)")
                .font(Theme.monoFont)
                .foregroundColor(Theme.money)
        }
        .cardStyle()
    }

    private var adjustedBounty: Int {
        Int(Double(offer.resaleBountyUsd) * qa.bonusMultiplier)
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Inspector notes").font(.headline).foregroundStyle(Theme.text)
            Text(qa.notes).font(.subheadline).foregroundStyle(Theme.text.opacity(0.85))
        }
        .cardStyle()
    }

    // MARK: - How-to-fix section

    private var failedItems: [PackagingChecklistItem] {
        qa.checklist.filter { !$0.passed }
    }

    private var retakeTips: [String] {
        failedItems.map { tip(for: $0.label) }
    }

    private var howToFixSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(Theme.molten)
                Text("How to fix it")
                    .font(.headline)
                    .foregroundStyle(Theme.text)
                Spacer()
                Text("PACKAGING COACH")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.5)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Theme.molten.opacity(0.18))
                    .foregroundColor(Theme.molten)
                    .clipShape(Capsule())
            }

            ForEach(failedItems) { c in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundColor(Theme.molten)
                            .font(.caption)
                        Text(c.label)
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(Theme.text)
                    }
                    Text(tip(for: c.label))
                        .font(.subheadline)
                        .foregroundStyle(Theme.textMuted)
                        .padding(.leading, 20)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.surfaceRaised)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Theme.molten.opacity(0.3), lineWidth: 1)
                )
            }
        }
        .cardStyle()
    }

    /// Maps a failed checklist label to a concrete retake tip for the host.
    private func tip(for label: String) -> String {
        let lower = label.lowercased()
        if lower.contains("dismantled") {
            return "Break the item down into shippable parts. Re-shoot showing the disassembled pieces side-by-side."
        }
        if lower.contains("wrapped") {
            return "Wrap each part in original packaging, blanket, or shrink wrap. Re-shoot from a wider angle so all parts are visible."
        }
        if lower.contains("corner") || lower.contains("edge") || lower.contains("pad") {
            return "Add foam or bubble wrap to corners and edges. Re-shoot from a 45° angle so the padding is visible."
        }
        if lower.contains("box") || lower.contains("container") || lower.contains("rigid") {
            return "Use the original box or a comparable rigid container. Soft bags or torn cardboard won't pass."
        }
        if lower.contains("tape") || lower.contains("closed") || lower.contains("seam") {
            return "Tape both top and bottom seams in an H pattern. Re-shoot from above showing the top seam."
        }
        if lower.contains("label") || lower.contains("dry") {
            return "Keep the label area clear, dry, and unobstructed. Wipe away dust and stickers. Re-shoot the label area straight on."
        }
        if lower.contains("damage") || lower.contains("stain") || lower.contains("wet") {
            return "Re-wrap with clean, dry material. If anything is torn or stained, replace before re-shooting."
        }
        return "Address this item and re-shoot from a clearer angle."
    }

    // MARK: - CTAs

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
            .foregroundColor(Theme.gunmetal)
            .background(Theme.earnGradient)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: Theme.molten.opacity(0.4), radius: 14, y: 6)
        }
    }

    private var retakeWithTipsButton: some View {
        Button {
            // Pop back to the existing PackagingCameraView so its AVCaptureSession
            // stays alive. Tips ride along via the shared AppRouter state.
            router.retakeTips = retakeTips
            router.path.removeLast()
        } label: {
            HStack {
                Image(systemName: "camera.fill")
                Text("Retake with tips")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .foregroundColor(Theme.gunmetal)
            .background(Theme.earnGradient)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: Theme.molten.opacity(0.4), radius: 12, y: 4)
        }
    }

    private var proceedAnywayButton: some View {
        Button {
            router.push(.hostDashboard(item, offer, qa))
        } label: {
            HStack { Text("Proceed anyway"); Image(systemName: "arrow.right") }
                .frame(maxWidth: .infinity)
                .font(.headline).foregroundColor(Theme.text)
                .padding(.vertical, 14)
                .background(Theme.surface)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Theme.border, lineWidth: 1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var verdictBackground: Color {
        switch qa.verdict {
        case "pass": return Theme.money
        case "needs_work": return Theme.warning
        default: return Theme.danger
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
