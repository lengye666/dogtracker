import SwiftUI
import MapKit

// MARK: - MKMapView 包装器 (兼容 iOS 15+)

struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    var dogLocation: CLLocationCoordinate2D?
    var trackPoints: [CLLocationCoordinate2D]
    var dogName: String
    
    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.showsUserLocation = true
        map.userTrackingMode = .follow
        map.showsCompass = true
        map.showsScale = true
        return map
    }
    
    func updateUIView(_ map: MKMapView, context: Context) {
        map.setRegion(region, animated: true)
        map.removeOverlays(map.overlays)
        map.removeAnnotations(map.annotations.filter { !($0 is MKUserLocation) })
        
        // 狗位置标注
        if let dogLoc = dogLocation {
            let pin = MKPointAnnotation()
            pin.coordinate = dogLoc
            pin.title = dogName
            map.addAnnotation(pin)
        }
        
        // 轨迹线
        if trackPoints.count > 1 {
            let polyline = MKPolyline(coordinates: trackPoints, count: trackPoints.count)
            map.addOverlay(polyline)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.blue.withAlphaComponent(0.5)
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            
            let id = "DogPin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: id)
                view?.canShowCallout = true
            }
            view?.annotation = annotation
            
            // 柴犬头像作为标注
            let size: CGFloat = 40
            let container = UIView(frame: CGRect(x: 0, y: 0, width: size + 10, height: size + 10))
            let imageView = UIImageView(frame: CGRect(x: 5, y: 5, width: size, height: size))
            imageView.contentMode = .scaleAspectFit
            
            // 用代码绘制柴犬脸
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
            let img = renderer.image { ctx in
                let rect = CGRect(x: 0, y: 0, width: size, height: size)
                // 橙色圆形
                UIColor.orange.setFill()
                ctx.fill(CGRect(x: 1, y: 1, width: size-2, height: size-2))
                // 白色面部
                UIColor.white.setFill()
                let faceRect = CGRect(x: size*0.18, y: size*0.18, width: size*0.64, height: size*0.55)
                let facePath = UIBezierPath(roundedRect: faceRect, cornerRadius: size*0.3)
                facePath.fill()
                // 眼睛
                UIColor.black.setFill()
                UIBezierPath(ovalIn: CGRect(x: size*0.3, y: size*0.28, width: size*0.08, height: size*0.10)).fill()
                UIBezierPath(ovalIn: CGRect(x: size*0.62, y: size*0.28, width: size*0.08, height: size*0.10)).fill()
                // 鼻子
                let noseRect = CGRect(x: size*0.38, y: size*0.5, width: size*0.24, height: size*0.1)
                UIBezierPath(roundedRect: noseRect, cornerRadius: size*0.05).fill()
            }
            imageView.image = img
            container.addSubview(imageView)
            view?.addSubview(container)
            
            return view
        }
    }
}

// MARK: - 地图追踪页

struct MapTrackView: View {
    @EnvironmentObject var vm: DogTrackerViewModel
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.9042, longitude: 116.4074),
        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    )
    
    var body: some View {
        ZStack(alignment: .top) {
            MapView(
                region: $region,
                dogLocation: vm.selectedDog?.lastLocation,
                trackPoints: vm.trackHistory.map { $0.coordinate },
                dogName: vm.selectedDog?.name ?? "狗子"
            )
            .ignoresSafeArea(edges: .top)
            
            VStack(spacing: 10) {
                Color.clear.frame(height: 50)
                
                // 距离标签
                if let dog = vm.selectedDog, let _ = dog.lastLocation {
                    HStack {
                        Spacer()
                        Text("距狗 \(Int.random(in: 50...500))m")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(.black.opacity(0.7)))
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
            }
        }
    }
}
