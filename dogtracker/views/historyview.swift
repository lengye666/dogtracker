import SwiftUI
import MapKit

// MARK: - 迷你地图 (MKMapView 兼容 iOS 15)

struct MiniLineMap: UIViewRepresentable {
    var points: [CLLocationCoordinate2D]
    var startLabel: String
    var endLabel: String
    
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.isScrollEnabled = false
        map.isZoomEnabled = false
        return map
    }
    
    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations)
        
        guard points.count > 1,
              let first = points.first,
              let last = points.last else { return }
        
        // 轨迹线
        let polyline = MKPolyline(coordinates: points, count: points.count)
        map.addOverlay(polyline)
        
        // 起点
        let startPin = MKPointAnnotation()
        startPin.coordinate = first
        startPin.title = startLabel
        map.addAnnotation(startPin)
        
        // 终点
        let endPin = MKPointAnnotation()
        endPin.coordinate = last
        endPin.title = endLabel
        map.addAnnotation(endPin)
        
        // 缩放以显示全轨迹
        let lats = points.map { $0.latitude }
        let lons = points.map { $0.longitude }
        let minLat = lats.min()!, maxLat = lats.max()!
        let minLon = lons.min()!, maxLon = lons.max()!
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.003, (maxLat - minLat) * 1.5),
            longitudeDelta: max(0.003, (maxLon - minLon) * 1.5)
        )
        map.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
    }
    
    func makeCoordinator() -> MapCoordinator { MapCoordinator() }
    
    class MapCoordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: polyline)
                r.strokeColor = .systemBlue
                r.lineWidth = 2
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            let id = "pin"
            var v = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
            if v == nil {
                v = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
                v?.canShowCallout = true
            }
            v?.annotation = annotation
            v?.markerTintColor = (annotation.title == "起点") ? .systemGreen : .systemRed
            return v
        }
    }
}

// MARK: - 历史轨迹页

struct HistoryView: View {
    @EnvironmentObject var vm: DogTrackerViewModel
    @State private var selectedTimeRange: TimeRange = .today
    @State private var showFullMap = false
    
    enum TimeRange: String, CaseIterable {
        case today = "今天", yesterday = "昨天", week = "本周"
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
                        ButtonView(range: range, isSelected: selectedTimeRange == range) {
                            withAnimation { selectedTimeRange = range }
                        }
                    }
                }
                .padding(.bottom, 16)
                
                // 迷你地图
                MiniLineMap(
                    points: vm.trackHistory.map { $0.coordinate },
                    startLabel: "起点",
                    endLabel: "终点"
                )
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
                
                // 时间线
                VStack(alignment: .leading, spacing: 0) {
                    Text("活动时间线")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.leading, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 12)
                    
                    ForEach(Array(vm.trackHistory.enumerated()), id: \.element.id) { index, point in
                        TimelineRowView(
                            index: index,
                            point: point,
                            isLast: index == vm.trackHistory.count - 1
                        )
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showFullMap) {
            FullTrackMapSheet(points: vm.trackHistory.map { $0.coordinate })
        }
    }
}

// MARK: - 子组件

struct ButtonView: View {
    let range: HistoryView.TimeRange
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: range.icon).font(.system(size: 12))
                Text(range.rawValue).font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : .secondary)
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(Capsule().fill(isSelected ? Color.accentColor : Color.white.opacity(0.08)))
        }
    }
}

struct TimelineRowView: View {
    let index: Int
    let point: TrackPoint
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(index == 0 ? .green : .blue.opacity(0.6))
                    .frame(width: 10, height: 10)
                if !isLast {
                    Rectangle().fill(.blue.opacity(0.3)).frame(width: 2)
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
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: date)
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
            HStack(alignment: .bottom, spacing: 2) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - 全屏轨迹图

struct FullTrackMapSheet: View {
    let points: [CLLocationCoordinate2D]
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // MKMapView 包装
            FullTrackMapWrapper(points: points)
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
    }
}

struct FullTrackMapWrapper: UIViewRepresentable {
    let points: [CLLocationCoordinate2D]
    
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.mapType = .hybrid
        return map
    }
    
    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeOverlays(map.overlays)
        guard points.count > 1 else { return }
        let polyline = MKPolyline(coordinates: points, count: points.count)
        map.addOverlay(polyline)
        
        let lats = points.map { $0.latitude }
        let lons = points.map { $0.longitude }
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max(0.003, (lats.max()! - lats.min()!) * 1.5),
            longitudeDelta: max(0.003, (lons.max()! - lons.min()!) * 1.5)
        )
        map.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
    }
    
    func makeCoordinator() -> MapCoord { MapCoord() }
    
    class MapCoord: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let p = overlay as? MKPolyline {
                let r = MKPolylineRenderer(polyline: p)
                r.strokeColor = .systemBlue; r.lineWidth = 3
                return r
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
