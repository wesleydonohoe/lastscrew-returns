import SwiftUI

struct AcceptHostView: View {
    @EnvironmentObject var router: AppRouter
    let item: ItemDetails
    let offer: HostOffer

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            VStack(spacing: 12) {
                ZStack {
                    Circle().fill(Theme.money.opacity(0.18)).frame(width: 96, height: 96)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56))
                        .foregroundColor(Theme.money)
                }
                Text("You're a host.")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.text)
                Text("$\(offer.signingBonusUsd) credited to your Wayfair Rewards.")
                    .font(Theme.moneyFont)
                    .foregroundStyle(Theme.money)
                Text("Next: dismantle the item, repack it in its original box (or comparable), then photograph it so our vision model can verify it's ship-ready. The labor bonus unlocks once QA passes.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()

            checklist

            Button {
                router.push(.packagingCamera(item, offer, []))
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Start packaging photo")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding(.vertical, 16).padding(.horizontal, 20)
                .foregroundColor(Theme.gunmetal)
                .background(Theme.earnGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Theme.molten.opacity(0.4), radius: 16, y: 8)
            }
        }
        .padding(24)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Accepted")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Dismantle + repackage checklist")
                .font(.headline)
                .foregroundStyle(Theme.text)
            ForEach([
                "Dismantle in reverse assembly order — keep hardware bagged",
                "Wrap each part in original packaging or blanket",
                "Pad corners and edges",
                "Use the original box or a comparable rigid container",
                "Tape both top and bottom seams",
                "Keep the label area clear and dry",
            ], id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle")
                        .foregroundColor(Theme.textMuted)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(Theme.text)
                }
            }
        }
        .cardStyle()
    }
}
