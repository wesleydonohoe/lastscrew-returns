import SwiftUI

struct HomeView: View {
    @EnvironmentObject var router: AppRouter
    @State private var user: UserSummary = UserSummary(firstName: "Wes", rewardsBalance: 95.04)
    @State private var items: [ItemDetails] = ItemDetails.demoFeed
    @State private var loaded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                greetingBlock
                rewardsBlock
                ordersHeader
                ForEach(items) { item in
                    Button { router.push(.manageItem(item)) } label: {
                        OrderRow(item: item)
                    }
                    .buttonStyle(.plain)
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
            Text("\(items.count) items in your home — \(eligibleCount) eligible for Last Screw")
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

    private var ordersHeader: some View {
        HStack {
            Text("My Orders")
                .font(Theme.headingFont)
                .foregroundStyle(Theme.text)
            Spacer()
            Text("See all")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.accent)
        }
        .padding(.top, 4)
    }

    private var eligibleCount: Int {
        items.filter { $0.status == "delivered" }.count
    }

    private func load() async {
        guard !loaded else { return }
        loaded = true
        do {
            let resp = try await APIClient.shared.fetchOrders()
            self.user = resp.user
            self.items = resp.items
        } catch {
            // Keep the .demoFeed so the UI never blanks.
        }
    }
}

private struct OrderRow: View {
    let item: ItemDetails

    var body: some View {
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
                statusBadge
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                Text("By \(item.brand)")
                    .font(.caption)
                    .foregroundStyle(Theme.textMuted)
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                    Text("Delivered \(prettyDate(item.deliveredAt))")
                        .font(.caption2)
                }
                .foregroundStyle(Theme.textFaint)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Image(systemName: "arrow.right")
                    .foregroundStyle(Theme.textMuted)
                if item.status == "delivered" {
                    Text("EARN")
                        .font(.caption2.weight(.heavy))
                        .tracking(1)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Theme.molten.opacity(0.18))
                        .foregroundColor(Theme.molten)
                        .overlay(Capsule().stroke(Theme.molten.opacity(0.5), lineWidth: 1))
                        .clipShape(Capsule())
                }
            }
        }
        .cardStyle()
    }

    private var statusBadge: some View {
        let label: String
        let color: Color
        switch item.status {
        case "delivered": label = "Delivered"; color = Theme.money
        case "in_transit": label = "In Transit"; color = Theme.amber
        case "returned": label = "Returned"; color = Theme.chromeDim
        default: label = item.status.capitalized; color = Theme.chromeDim
        }
        return Text(label)
            .font(.caption2.weight(.heavy))
            .tracking(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .overlay(Capsule().stroke(color.opacity(0.45), lineWidth: 1))
            .clipShape(Capsule())
    }

    private func prettyDate(_ raw: String) -> String {
        // raw is "YYYY-MM-DD" — render as "Mon, MMM d"
        let inFmt = DateFormatter()
        inFmt.dateFormat = "yyyy-MM-dd"
        inFmt.timeZone = TimeZone(secondsFromGMT: 0)
        guard let d = inFmt.date(from: raw) else { return raw }
        let outFmt = DateFormatter()
        outFmt.dateFormat = "EEE, MMM d"
        return outFmt.string(from: d)
    }
}
