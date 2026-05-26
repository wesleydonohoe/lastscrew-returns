import Foundation
import UIKit

@MainActor
final class PackagingViewModel: ObservableObject {
    @Published var isVerifying = false
    @Published var result: PackagingQAResult?
    @Published var errorMessage: String?

    func verify(orderId: String, image: UIImage) async {
        isVerifying = true
        errorMessage = nil
        defer { isVerifying = false }
        do {
            self.result = try await APIClient.shared.verifyPackaging(orderId: orderId, image: image)
        } catch {
            self.errorMessage = (error as? APIError)?.errorDescription ?? error.localizedDescription
            // Worker offline? Fake a "needs_work" verdict so the demo continues.
            self.result = PackagingQAResult(
                orderId: orderId,
                verdict: "needs_work",
                score: 0.72,
                checklist: [
                    .init(label: "Item fully wrapped", passed: true, detail: nil),
                    .init(label: "Corners and edges padded", passed: false, detail: "Add padding on corners"),
                    .init(label: "Box closed and taped", passed: true, detail: nil),
                    .init(label: "Label area clear and dry", passed: true, detail: nil),
                    .init(label: "No visible damage", passed: true, detail: nil),
                ],
                notes: "Looks close — add corner padding and re-snap.",
                bonusMultiplier: 0.9,
                source: "mock"
            )
        }
    }
}
