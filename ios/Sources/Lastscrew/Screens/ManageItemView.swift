import SwiftUI

struct ManageItemView: View {
    @EnvironmentObject var router: AppRouter
    @State private var item: ItemDetails = .demo
    @State private var loadFailed = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                itemCard
                actionRow(icon: "shippingbox.fill", title: "Track My Package")
                actionRow(icon: "square.and.pencil", title: "Write a Product Review")
                lastScrewCallout
                actionRow(icon: "headphones", title: "Something else")
            }
            .padding(20)
        }
        .background(Theme.bg.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Manage Your Item")
                    .font(.headline)
                    .foregroundStyle(Theme.text)
            }
        }
        .task { await loadItem() }
    }

    private var header: some View {
        HStack {
            Text("wayfair.com")
                .font(.footnote)
                .foregroundStyle(Theme.textMuted)
            Spacer()
        }
    }

    private var itemCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image("MattressHero")
                .resizable()
                .scaledToFill()
                .frame(width: 110, height: 110)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 8) {
                Text("Delivered")
                    .font(.caption.weight(.heavy))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.money.opacity(0.18))
                    .foregroundColor(Theme.money)
                    .overlay(Capsule().stroke(Theme.money.opacity(0.5), lineWidth: 1))
                    .clipShape(Capsule())
                Text(item.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.text)
                    .lineLimit(2)
                Text("Quantity: 1")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textMuted)
                Text("Last Package Delivered: Sun, May 17")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textMuted)
            }
            Spacer()
        }
        .cardStyle()
    }

    private func actionRow(icon: String, title: String) -> some View {
        Button(action: {}) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 36)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundStyle(Theme.textMuted)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var lastScrewCallout: some View {
        Button {
            router.push(.returnChooser(item))
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle().fill(Theme.gunmetal.opacity(0.35))
                        Image(systemName: "shippingbox.and.arrow.backward.fill")
                            .foregroundColor(Theme.chrome)
                    }
                    .frame(width: 36, height: 36)
                    Text("Return or replace my item")
                        .font(.system(size: 17, weight: .heavy))
                        .foregroundColor(Theme.chrome)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(Theme.chrome.opacity(0.9))
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("NEW")
                        .font(.caption2.weight(.heavy))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Theme.chrome)
                        .foregroundColor(Theme.gunmetal)
                        .clipShape(Capsule())
                    Text("Dismantle it. Get paid for it.")
                        .font(.subheadline.weight(.heavy))
                        .foregroundColor(Theme.chrome)
                }
            }
            .padding(18)
            .background(Theme.earnGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Theme.molten.opacity(0.45), radius: 16, y: 8)
        }
        .buttonStyle(.plain)
    }

    private func loadItem() async {
        do {
            let live = try await APIClient.shared.fetchItem(orderId: ItemDetails.demo.orderId)
            self.item = live
        } catch {
            self.loadFailed = true   // keep the .demo fallback so UI never blanks
        }
    }
}

#Preview {
    NavigationStack { ManageItemView().environmentObject(AppRouter()) }
}
