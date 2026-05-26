import SwiftUI
import PhotosUI

struct PackagingCameraView: View {
    @EnvironmentObject var router: AppRouter
    let item: ItemDetails
    let offer: HostOffer

    @StateObject private var camera = CameraController()
    @StateObject private var vm = PackagingViewModel()
    @State private var pickerItem: PhotosPickerItem?
    @State private var fallbackImage: UIImage?
    @State private var isCapturing = false

    var body: some View {
        ZStack {
            Theme.void.ignoresSafeArea()

            if camera.isReady {
                CameraPreviewView(session: camera.session)
                    .ignoresSafeArea()
            } else if camera.setupError != nil {
                fallbackPicker
            } else {
                ProgressView()
                    .tint(Theme.chrome)
            }

            VStack {
                topBar
                Spacer()
                framingGuide
                Spacer()
                shutterRow
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { camera.startIfNeeded() }
        .onDisappear { camera.stop() }
        .onChange(of: pickerItem) { _, newItem in
            Task { await loadPicked(newItem) }
        }
    }

    private var topBar: some View {
        HStack {
            Button { router.path.removeLast() } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(Theme.chrome)
                    .padding(12)
                    .background(Theme.void.opacity(0.55))
                    .clipShape(Circle())
            }
            Spacer()
            Text("Verify packaging")
                .font(.headline)
                .foregroundColor(Theme.chrome)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(Theme.void.opacity(0.55))
                .clipShape(Capsule())
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(16)
    }

    private var framingGuide: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .strokeBorder(Theme.molten.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
            .frame(width: 280, height: 380)
            .overlay(
                Text("Frame the whole package")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(Theme.chrome)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Theme.void.opacity(0.55))
                    .clipShape(Capsule())
                    .offset(y: -180)
            )
    }

    private var shutterRow: some View {
        HStack(spacing: 40) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title3)
                    .foregroundColor(Theme.chrome)
                    .padding(14)
                    .background(Theme.void.opacity(0.55))
                    .clipShape(Circle())
            }

            Button {
                Task { await snap() }
            } label: {
                ZStack {
                    Circle().stroke(Theme.chrome, lineWidth: 4).frame(width: 78, height: 78)
                    Circle().fill(Theme.chrome).frame(width: 64, height: 64)
                    if isCapturing || vm.isVerifying {
                        ProgressView().tint(Theme.molten)
                    }
                }
            }
            .disabled(!camera.isReady || isCapturing || vm.isVerifying)

            Color.clear.frame(width: 50)
        }
        .padding(.bottom, 36)
    }

    private var fallbackPicker: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.slash.fill").font(.system(size: 44)).foregroundColor(Theme.chrome)
            Text(camera.setupError ?? "")
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.chrome)
                .padding(.horizontal, 32)
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text("Pick from library")
                    .font(.headline)
                    .padding(.horizontal, 24).padding(.vertical, 14)
                    .background(Theme.earnGradient)
                    .foregroundColor(Theme.gunmetal)
                    .clipShape(Capsule())
            }
        }
    }

    private func snap() async {
        guard camera.isReady else { return }
        isCapturing = true
        defer { isCapturing = false }
        do {
            let img = try await camera.capture()
            await vm.verify(orderId: item.orderId, image: img)
            if let res = vm.result {
                router.push(.packagingResult(item, offer, res))
            }
        } catch {
            vm.errorMessage = error.localizedDescription
        }
    }

    private func loadPicked(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        if let data = try? await item.loadTransferable(type: Data.self),
           let img = UIImage(data: data) {
            self.fallbackImage = img
            await vm.verify(orderId: self.item.orderId, image: img)
            if let res = vm.result {
                router.push(.packagingResult(self.item, offer, res))
            }
        }
    }
}
