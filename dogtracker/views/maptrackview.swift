import SwiftUI
import MapKit

struct MapTrackView: View {
    @EnvironmentObject var vm: DogTrackerViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    @State private var position: MapCameraPosition = .automatic
    
    var body: some View {
        ZStack(alignment: .top) {
            // 地图
            Map(position: $position) {
                // 用户位置
                UserAnnotation()
                
                // 狗的位置
                if let dog = vm.selectedDog, let loc = dog.lastLocation {
                    Annotation(dog.name, coordinate: loc) {
                        DogAnnotationView(name: dog.name)
                    }
                }
                
                // 轨迹线
                MapPolyline(coordinates: vm.trackHistory.map { $0.coordinate })
                    .stroke(.blue.opacity(0.4), lineWidth: 3)
            }
            .mapStyle(.standard(elevation: .flat, emphasis: .muted))
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }
            .ignoresSafeArea(edges: .top)
            
            // 顶部信息覆盖层
            VStack(spacing: 10) {
                // 安全区占位
                Color.clear.frame(height: 50)
                
                // 距离标签
                if let dog = vm.selectedDog, let loc = dog.lastLocation {
                    HStack {
                        Spacer()
                        DistanceLabel(dog: dog, dogLocation: loc)
                        Spacer()
                    }
                }
                
                DogStatusCard()
                    .padding(.horizontal, 16)
                
                Spacer()
            }
        }
        .onAppear {
            if let dog = vm.selectedDog, let loc = dog.lastLocation {
                region.center = loc
                position = .region(region)
            }
        }
    }
}

// MARK: - 狗子地图标注

struct DogAnnotationView: View {
    let name: String
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(.orange.opacity(0.25))
                    .frame(width: 48, height: 48)
                    .scaleEffect(isAnimating ? 1.5 : 1.0)
                    .opacity(isAnimating ? 0 : 0.5)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
                
                ShibaAvatar(named: name, size: 36, connected: true)
            }
            
            Text(name)
                .font(.system(size: 11, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .onAppear { isAnimating = true }
    }
}

// MARK: - 距离标签

struct DistanceLabel: View {
    let dog: DogTag
    let dogLocation: CLLocationCoordinate2D
    @State private var distance: Double = 0
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "location.fill")
                .font(.system(size: 11))
            Text("距狗 \(Int(distance))m")
                .font(.system(size: 13, weight: .semibold))
            Circle()
                .fill(.green)
                .frame(width: 6, height: 6)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(.black.opacity(0.7))
        )
        .onAppear {
            // 演示：模拟距离
            distance = Double.random(in: 50...500)
            // 真实场景使用: distance = userLocation.distance(from: dogLocation)
        }
    }
}
