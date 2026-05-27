import Foundation
import Security
import CommonCrypto

// MARK: - Find My 直接查询服务
// 通过 Apple ID 登录 Find My 网络，直接获取 Tag 位置
// 无需服务器中转

class FindMyService: ObservableObject {
    @Published var isAuthenticated = false
    @Published var locations: [String: FindMyLocation] = [:]  // tagID → location
    @Published var lastError: String?
    
    private var appleID: String = ""
    private var anisetteData: [String: String] = [:]
    private var sessionToken: String?
    private var pollingTimer: Timer?
    
    struct FindMyLocation: Codable {
        let latitude: Double
        let longitude: Double
        let horizontalAccuracy: Double?
        let timestamp: Date
        let isLive: Bool
    }
    
    // MARK: - 登录
    
    func authenticate(appleID: String, password: String, completion: @escaping (Bool) -> Void) {
        self.appleID = appleID
        
        // Apple ID 登录（简化版 — 实际需要完整的 GrandSlam 认证流程）
        // 生成 Anisette 数据
        anisetteData = generateAnisette()
        
        // 模拟登录成功（接 nRF52 Tag 后替换为真实 Apple 认证）
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.isAuthenticated = true
            self?.sessionToken = "demo_token_\(UUID().uuidString.prefix(8))"
            completion(true)
        }
    }
    
    // MARK: - 轮询 Tag 位置
    
    func startPolling(tagIDs: [String], interval: TimeInterval = 5.0) {
        stopPolling()
        
        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            for tagID in tagIDs {
                self?.fetchLocation(for: tagID)
            }
        }
        // 立即执行一次
        for tagID in tagIDs {
            fetchLocation(for: tagID)
        }
    }
    
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    // MARK: - 查单个 Tag 位置
    
    func fetchLocation(for tagID: String) {
        guard isAuthenticated else { return }
        
        // Find My 网络查询 API
        // POST https://p156-fmf.icloud.com/fmf/refreshClient
        // Body: { "clientContext": { ... }, "selectedDevice": tagID }
        
        // 模拟返回（真实部署时替换为实际 API 调用）
        let demoLocations: [FindMyLocation] = [
            FindMyLocation(latitude: 39.9042 + Double.random(in: -0.001...0.001),
                          longitude: 116.4074 + Double.random(in: -0.001...0.001),
                          horizontalAccuracy: Double.random(in: 3...20),
                          timestamp: Date(),
                          isLive: true)
        ]
        
        if let loc = demoLocations.randomElement() {
            DispatchQueue.main.async { [weak self] in
                self?.locations[tagID] = loc
            }
        }
    }
    
    // MARK: - Anisette 生成
    
    func generateAnisette() -> [String: String] {
        // Anisette 是 Apple 双因素认证的一环
        // 真实部署需提取设备上的 Anisette 数据
        // 或用开源 anisette-server 提供
        return [
            "X-Apple-I-MD": "AAAB",
            "X-Apple-I-MD-M": UUID().uuidString,
            "X-Apple-I-TimeZone": TimeZone.current.identifier,
            "X-Apple-I-Locale": Locale.current.identifier
        ]
    }
    
    // MARK: - Crypto helpers
    
    func hmacSHA256(key: Data, data: Data) -> Data {
        var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
        digest.withUnsafeMutableBytes { d in
            data.withUnsafeBytes { b in
                key.withUnsafeBytes { k in
                    CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA256), k.baseAddress!, key.count, b.baseAddress!, data.count, d.baseAddress!)
                }
            }
        }
        return digest
    }
}
