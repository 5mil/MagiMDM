import Foundation

struct DeviceRow: Identifiable, Decodable {
    let id: Int
    let name: String
    let platform: String
    let status: String
    let last_seen_at: String?
    let policy: String?
}

struct DeviceList: Decodable { let devices: [DeviceRow] }

final class API {
    let base: URL
    private var cookie: String?

    init(base: String) {
        self.base = URL(string: base) ?? URL(string: "http://127.0.0.1:8788")!
    }

    func login(user: String, password: String) async throws {
        var req = URLRequest(url: base.appendingPathComponent("login"))
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = "username=\(enc(user))&password=\(enc(password))".data(using: .utf8)
        let (_, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse {
            cookie = http.value(forHTTPHeaderField: "Set-Cookie")
            guard (200...399).contains(http.statusCode) else { throw URLError(.userAuthenticationRequired) }
        }
    }

    func devices() async throws -> [DeviceRow] {
        var req = URLRequest(url: base.appendingPathComponent("api/parent/devices"))
        if let cookie { req.setValue(cookie, forHTTPHeaderField: "Cookie") }
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(DeviceList.self, from: data).devices
    }

    func bulk(policy: String) async throws {
        try await form("/devices/bulk", "policy=\(enc(policy))")
    }

    func lockAll() async throws {
        try await form("/devices/bulk", "command=lock")
    }

    private func form(_ path: String, _ body: String) async throws {
        var req = URLRequest(url: base.appendingPathComponent(path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))))
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        if let cookie { req.setValue(cookie, forHTTPHeaderField: "Cookie") }
        req.httpBody = body.data(using: .utf8)
        _ = try await URLSession.shared.data(for: req)
    }

    private func enc(_ s: String) -> String {
        s.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? s
    }
}
