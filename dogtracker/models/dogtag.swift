import Foundation
import CoreLocation

struct DogTag: Identifiable, Codable {
    let id: String
    let name: String
    let breed: String
    let tagMAC: String           // BLE 硬件地址
    let findMyID: String         // Find My 配对 ID
    var lastLocation: CLLocationCoordinate2D?
    var lastUpdate: Date?
    var batteryLevel: Int        // 0-100
    var isConnected: Bool
    
    // BLE 近距信息
    var proximityDistance: Double?  // 估算距离 米
    var rssi: Int?                  // 信号强度 dBm
    var proximityDirection: ProximityDirection?
}

enum ProximityDirection: String, Codable {
    case cold    // 远
    case warm    // 中
    case hot     // 近
    case found   // 非常近
    
    var emoji: String {
        switch self {
        case .cold:  return "❄️"
        case .warm:  return "🌡️"
        case .hot:   return "🔥"
        case .found: return "✅"
        }
    }
    
    var color: String {
        switch self {
        case .cold:  return "systemBlue"
        case .warm:  return "systemOrange"
        case .hot:   return "systemRed"
        case .found: return "systemGreen"
        }
    }
}

struct LocationRecord: Identifiable, Codable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
    let accuracy: Double          // 米
    let source: LocationSource
}

enum LocationSource: String, Codable {
    case findMy
    case ble
    case uwb
    case manual
}

struct TrackPoint: Identifiable, Codable {
    let id: UUID
    let coordinate: CLLocationCoordinate2D
    let timestamp: Date
}

// MARK: - Codable 支持 CLLocationCoordinate2D

extension CLLocationCoordinate2D: Codable {
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            latitude: try c.decode(Double.self, forKey: .latitude),
            longitude: try c.decode(Double.self, forKey: .longitude)
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(latitude, forKey: .latitude)
        try c.encode(longitude, forKey: .longitude)
    }
}
