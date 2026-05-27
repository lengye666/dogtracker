import SwiftUI
import MapKit

struct HistoryView: View {
    @EnvironmentObject var vm: DogTrackerViewModel
    @State private var selectedTimeRange: TimeRange = .today
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showFullMap = false
    
    enum TimeRange: String, CaseIterable {
        case today = "今天"
        case yesterday = "昨天"
        case week = "本周"
        
        var icon: String {
            switch self {
            case .today: return "sun.max"
            case .yesterday: return "moon"
            case .week: return "calendar"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 标题
                VStack(spacing: 4) {
                    Text("历史轨迹")
                        .font(.system(size: 28, weight: .bold))
                    Text("今天走了约 3.2 公里")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
                .padding(.bottom, 20)
                
                // 时间筛选
                HStack(spacing: 10) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Button(action: { withAnimation { selectedTimeRange = range } }) {
                            HStack(spacing: 5) {
                                Image(systemName: range.icon)
                                    .font(.system(size: 12))
                                Text(range.rawValue)
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundColor(selectedTimeRange == range ? .white : .secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedTimeRange == range ?
                                AnyShapeStyle(Capsule().fill(.accentColor)) :
                                AnyShapeStyle(Capsule().fill(.ultraThinMaterial))
                            )
                        }
                    }
                }
                .padding(.bottom, 16)
                
                // 迷你地图预览
                Map(position: $cameraPosition) {
                    MapPolyline(coordinates: vm.trackHistory.map { $0.coordinate })
                        .stroke(.blue, lineWidth: 2)
                    
                    if let first = vm.trackHistory.first {
                        Annotation("起点", coordinate: first.coordinate) {
                            Image(systemName: "house.circle.fill")
                                .font(.title2)
                                .foregroundColor(.green)
                                .background(Circle().fill(.white).frame(width: 18, height: 18))
                        }
                    }
                    if let last = vm.trackHistory.last {
                        Annotation("终点", coordinate: last.coordinate) {
                            Image(systemName: "flag.circle.fill")
                                .font(.title2)
                                .foregroundColor(.red)
                                .background(Circle().fill(.white).frame(width: 18, height: 18))
                        }
                    }
                }
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
                .shadow(color: .black.opacity(0.2), radius: 8)
                .onTapGesture { showFullMap = true }
                
                // 统计卡片
                HStack(spacing: 12) {
                    StatCard(icon: "figure.walk", value: "3.2", unit: "公里", color: .blue)
                    StatCard(icon: "clock", value: "48", unit: "分钟", color: .orange)
                    StatCard(icon: "flame", value: "320", unit: "千卡", color: .red)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // 轨迹时间线
                VStack(alignment: .leading, spacing: 0) {
                    Text("活动时间线")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.leading, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 12)
                    
                    ForEach(Array(vm.trackHistory.enumerated()), id: \.element.id) { index, point in
                        TimelineRow(index: index, point: point, isLast: index == vm.trackHistory.count - 1)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showFullMap) {
            FullTrackMapView(points: vm.trackHistory)
        }
    }
}

// MARK: - 统计卡片

struct StatCard: View {
    let icon: String
    let value: String
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            HStack(alignment: .lastBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - 时间线行

struct TimelineRow: View {
    let index: Int
    let point: TrackPoint
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 时间线
            VStack(spacing: 0) {
                Circle()
                    .fill(index == 0 ? .green : .blue.opacity(0.6))
                    .frame(width: 10, height: 10)
                if !isLast {
                    Rectangle()
                        .fill(.blue.opacity(0.3))
                        .frame(width: 2)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(formatTime(point.timestamp))
                    .font(.system(size: 13, weight: .semibold))
                Text(String(format: "%.5f, %.5f", point.coordinate.latitude, point.coordinate.longitude))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, isLast ? 4 : 4)
    }
    
    func formatTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}

// MARK: - 全屏轨迹地图

struct FullTrackMapView: View {
    let points: [TrackPoint]
    @State private var position: MapCameraPosition = .automatic
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Map(position: $position) {
                MapPolyline(coordinates: points.map { $0.coordinate })
                    .stroke(.blue, lineWidth: 3)
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .ignoresSafeArea()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .shadow(radius: 4)
            }
            .padding(.top, 50)
            .padding(.trailing, 16)
        }
        .onAppear {
            if points.count > 1 {
                let lats = points.map { $0.coordinate.latitude }
                let lons = points.map { $0.coordinate.longitude }
                let minLat = lats.min()!, maxLat = lats.max()!
                let minLon = lons.min()!, maxLon = lons.max()!
                let center = CLLocationCoordinate2D(
                    latitude: (minLat + maxLat) / 2,
                    longitude: (minLon + maxLon) / 2
                )
                let span = MKCoordinateSpan(
                    latitudeDelta: max(0.003, (maxLat - minLat) * 1.5),
                    longitudeDelta: max(0.003, (maxLon - minLon) * 1.5)
                )
                position = .region(MKCoordinateRegion(center: center, span: span))
            }
        }
    }
}
