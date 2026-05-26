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
                    Circle().fill(Theme.green.opacity(0.15)).frame(width: 96, height: 96)
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 56))
                        .foregroundColor(Theme.green)
                }
                Text("You're a host.")
                    .font(Theme.titleFont)
                Text("$\(offer.signingBonusUsd) credited to your Wayfair Rewards.")
                    .font(.headline)
                    .foregroundStyle(Theme.purple)
                Text("Next: wrap the item in its original packaging (or comparable), then photograph it so we can verify it's ship-ready.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer()

            checklist

            Button {
                router.push(.packagingCamera(item, offer))
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Start packaging photo")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding(.vertical, 16).padding(.horizontal, 20)
                .foregroundColor(.white)
                .background(Theme.earnGradient)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .padding(24)
        .background(Theme.bg.ignoresSafeArea())
        .navigationTitle("Accepted")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var checklist: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Packaging checklist")
                .font(.headline)
            ForEach([
                "Wrap fully in blanket, shrink wrap, or original packaging",
                "Pad corners and edges",
                "Use a rigid container or original box",
                "Tape both top and bottom seams",
                "Keep label area clear and dry",
            ], id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle")
                        .foregroundColor(Theme.muted)
                    Text(item)
                        .font(.subheadline)
                }
            }
        }
        .cardStyle()
    }
}
