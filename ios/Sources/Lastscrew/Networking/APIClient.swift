import Foundation
import UIKit

enum APIError: LocalizedError {
    case badStatus(Int, String)
    case decode(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .badStatus(let code, let body): return "Worker returned \(code): \(body)"
        case .decode(let e): return "Decode failed: \(e.localizedDescription)"
        case .network(let e): return "Network error: \(e.localizedDescription)"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let baseURL: URL

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 90
        cfg.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: cfg)

        // Honor LASTSCREW_API_BASE if set (Info.plist or scheme env var).
        let plistValue = Bundle.main.object(forInfoDictionaryKey: "LASTSCREW_API_BASE") as? String
        let envValue = ProcessInfo.processInfo.environment["LASTSCREW_API_BASE"]
        let raw = envValue ?? plistValue ?? "http://127.0.0.1:8787"
        self.baseURL = URL(string: raw) ?? URL(string: "http://127.0.0.1:8787")!
    }

    func fetchItem(orderId: String) async throws -> ItemDetails {
        try await get("/api/lastscrew/items/\(orderId)")
    }

    func requestOffer(orderId: String, zip: String) async throws -> HostOffer {
        try await post("/api/lastscrew/offer", body: ["orderId": orderId, "zip": zip])
    }

    func verifyPackaging(orderId: String, image: UIImage, photoDescription: String? = nil) async throws -> PackagingQAResult {
        var body: [String: Any] = ["orderId": orderId]
        if let jpeg = image.jpegData(compressionQuality: 0.7) {
            body["imageBase64"] = jpeg.base64EncodedString()
        }
        if let photoDescription { body["photoDescription"] = photoDescription }
        return try await post("/api/lastscrew/verify", body: body)
    }

    // MARK: - Internals

    private func get<T: Decodable>(_ path: String) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "GET"
        return try await send(req)
    }

    private func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await send(req)
    }

    private func send<T: Decodable>(_ req: URLRequest) async throws -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.network(error)
        }
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? -1
            let bodyText = String(data: data, encoding: .utf8) ?? ""
            throw APIError.badStatus(code, bodyText.prefix(300).description)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decode(error)
        }
    }
}
