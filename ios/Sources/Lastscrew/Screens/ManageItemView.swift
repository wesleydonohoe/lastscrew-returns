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
                Text("Manage Your Item").font(.headline)
            }
        }
        .task { await loadItem() }
    }

    private var header: some View {
        HStack {
            Text("wayfair.com")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
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
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.85, green: 0.95, blue: 0.86))
                    .foregroundColor(Color(red: 0.10, green: 0.35, blue: 0.18))
                    .clipShape(Capsule())
                Text(item.name)
                    .font(.system(size: 17, weight: .semibold))
                    .lineLimit(2)
                Text("Quantity: 1")
                    .font(.subheadline)
                    .foregroundStyle(Theme.text.opacity(0.8))
                Text("Last Package Delivered: Sun, May 17")
                    .font(.subheadline)
                    .foregroundStyle(Theme.text.opacity(0.8))
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
                    .foregroundStyle(Theme.purple)
                    .frame(width: 36)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.text)
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundStyle(Theme.text)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.cardStroke, lineWidth: 1)
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
                        Circle().fill(Color.white.opacity(0.2))
                        Image(systemName: "shippingbox.and.arrow.backward.fill")
                            .foregroundColor(.white)
                    }
                    .frame(width: 36, height: 36)
                    Text("Return or replace my item")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.white.opacity(0.9))
                }
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("NEW")
                        .font(.caption2.weight(.heavy))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.white)
                        .foregroundColor(Theme.purple)
                        .clipShape(Capsule())
                    Text("Don't dismantle it — earn from it.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white.opacity(0.95))
                }
            }
            .padding(18)
            .background(Theme.earnGradient)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Theme.purple.opacity(0.25), radius: 12, y: 6)
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
