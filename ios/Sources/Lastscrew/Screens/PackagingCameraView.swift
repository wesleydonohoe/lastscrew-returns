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
    @State private var showCoach = true

    /// Tips are passed in via AppRouter so popping back to this view (instead
    /// of pushing a fresh one) keeps the camera session alive across retakes.
    private var retakeTips: [String] { router.retakeTips }
    @State private var spinAngle: Double = 0
    @State private var visionAgentStatus: String = "preparing…"

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
                if !retakeTips.isEmpty && showCoach {
                    coachCard
                        .padding(.horizontal, 16)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
                framingGuide
                Spacer()
                if isCapturing || vm.isVerifying {
                    visionAgentPanel
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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

    // MARK: - Coaching overlay (visible on retake with tips)

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(Theme.molten)
                Text("PACKAGING COACH")
                    .font(.caption2.weight(.heavy)).tracking(1.5)
                    .foregroundColor(Theme.molten)
                Spacer()
                Button { withAnimation { showCoach = false } } label: {
                    Image(systemName: "xmark")
                        .font(.caption2.weight(.heavy))
                        .foregroundColor(Theme.chrome)
                        .padding(4)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
            }
            ForEach(Array(retakeTips.prefix(3).enumerated()), id: \.offset) { _, tip in
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.caption)
                        .foregroundColor(Theme.molten)
                    Text(tip)
                        .font(.caption)
                        .foregroundColor(Theme.chrome)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.void.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.molten.opacity(0.45), lineWidth: 1)
        )
    }

    // MARK: - Vision agent activity panel (visible while QA is running)

    private var visionAgentPanel: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Theme.molten, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 12, height: 12)
                    .rotationEffect(.degrees(spinAngle))
                    .onAppear {
                        withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false)) {
                            spinAngle = 360
                        }
                    }
                Text("VISION AGENT")
                    .font(.caption.weight(.heavy)).tracking(2)
                    .foregroundColor(Theme.molten)
                Spacer()
                Text("baseten · qwen2-vl")
                    .font(Theme.monoFont)
                    .foregroundColor(Theme.chromeFaint)
            }
            Text(visionAgentStatus)
                .font(Theme.monoFont)
                .foregroundColor(Theme.chrome)
                .id(visionAgentStatus)
                .transition(.opacity)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.void.opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Theme.molten.opacity(0.45), lineWidth: 1)
        )
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
            // A new capture invalidates the previous retake tips.
            router.retakeTips = []
            // Run the phase animation AND the verify call in parallel, and
            // wait for BOTH before navigating. This guarantees the user sees
            // the full agent stream even when the mock returns instantly.
            async let cycleDone: Void = cycleVisionStatus()
            async let verifyDone: Void = vm.verify(orderId: item.orderId, image: img)
            _ = await cycleDone
            _ = await verifyDone
            if let res = vm.result {
                router.push(.packagingResult(item, offer, res))
            }
        } catch {
            vm.errorMessage = error.localizedDescription
        }
    }

    private func cycleVisionStatus() async {
        let phases = [
            "uploading photo to baseten…",
            "detecting box edges…",
            "checking corner padding…",
            "inspecting tape seams…",
            "reading label area…",
            "scoring shippability…",
        ]
        for phase in phases {
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    visionAgentStatus = phase
                }
            }
            try? await Task.sleep(nanoseconds: 750_000_000)
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
