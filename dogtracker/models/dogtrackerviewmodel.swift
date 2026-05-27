import Foundation
import SwiftUI
import CoreLocation
import Combine

class DogTrackerViewModel: ObservableObject {
    @Published var dogs: [DogTag] = []
    @Published var selectedDog: DogTag?
    @Published var trackHistory: [TrackPoint] = []
    @Published var bleDistance: Double?          // 估算距离（米）
    @Published var bleRSSI: Int?                 // 信号强度
    @Published var bleDirection: ProximityDirection = .cold
    @Published var isScanning: Bool = false
    @Published var lastUpdateTime: Date?
    @Published var alertMessage: String?
    
    private let bleScanner = BLEScanner()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadDemoData()
        bleScanner.$rssi
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rssi in
                self?.bleRSSI = rssi
                self?.updateProximity(from: rssi)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - 演示数据（接硬件后替换）
    
    func loadDemoData() {
        // 柴犬小八
        let xiaoba = DogTag(
            id: UUID().uuidString,
            name: "小八",
            breed: "柴犬",
            tagMAC: "AA:BB:CC:DD:EE:01",
            findMyID: "fm_xiaoba_001",
            lastLocation: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
            lastUpdate: Date(),
            batteryLevel: 82,
            isConnected: true
        )
        dogs = [xiaoba]
        selectedDog = xiaoba
        
        // 演示轨迹
        trackHistory = generateDemoTrack()
    }
    
    // MARK: - BLE 距离估算
    
    func updateProximity(from rssi: Int?) {
        guard let rssi = rssi else {
            bleDirection = .cold
            bleDistance = nil
            return
        }
        
        // RSSI → 距离估算（粗略公式，真实环境需校准）
        // 基准：1米处 RSSI = -59dBm，衰减指数 2.0
        let rssiAt1m = -59.0
        let txPower = rssiAt1m
        let envFactor = 2.0
        
        if Double(rssi) >= txPower {
            bleDistance = 1.0
        } else {
            bleDistance = pow(10, (txPower - Double(rssi)) / (10.0 * envFactor))
        }
        
        let distance = bleDistance ?? 100
        switch distance {
        case 0..<3:   bleDirection = .found
        case 3..<10:  bleDirection = .hot
        case 10..<30: bleDirection = .warm
        default:      bleDirection = .cold
        }
        
        lastUpdateTime = Date()
    }
    
    func startScanning() {
        isScanning = true
        bleScanner.startScanning(for: selectedDog?.tagMAC)
    }
    
    func stopScanning() {
        isScanning = false
        bleScanner.stopScanning()
    }
    
    // MARK: - 模拟轨迹数据
    
    func generateDemoTrack() -> [TrackPoint] {
        let base = CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074)
        var points: [TrackPoint] = []
        let calendar = Calendar.current
        let now = Date()
        
        // 模拟过去 2 小时的轨迹
        let offsets: [(Double, Double)] = [
            (0, 0), (0.0002, 0.0003), (0.0004, 0.0006), (0.0007, 0.0004),
            (0.0009, 0.0008), (0.0011, 0.0010), (0.0013, 0.0009),
            (0.0010, 0.0012), (0.0007, 0.0014), (0.0003, 0.0011),
            (0, 0.0005), (0.0002, 0.0002)
        ]
        
        for (i, offset) in offsets.enumerated() {
            let point = TrackPoint(
                id: UUID(),
                coordinate: CLLocationCoordinate2D(
                    latitude: base.latitude + offset.0,
                    longitude: base.longitude + offset.1
                ),
                timestamp: calendar.date(byAdding: .minute, value: -((offsets.count - i) * 10), to: now) ?? now
            )
            points.append(point)
        }
        
        return points
    }
}
