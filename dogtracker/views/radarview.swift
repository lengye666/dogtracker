import SwiftUI

struct RadarView: View {
    @EnvironmentObject var vm: DogTrackerViewModel
    @State private var radarRotation: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var dotPositions: [CGSize] = Array(repeating: .zero, count: 6)
    @State private var signalBars: [CGFloat] = [0.2, 0.4, 0.6, 0.8, 1.0]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 标题
                VStack(spacing: 4) {
                    Text("近距雷达")
                        .font(.system(size: 28, weight: .bold))
                    Text(vm.isScanning ? "正在搜索..." : "点击下方按钮开始搜索")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
                
                // 雷达圆盘
                ZStack {
                    // 背景波纹
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.accentColor.opacity(0.3), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                            .frame(width: 120 + CGFloat(i) * 80)
                            .scaleEffect(pulseScale + CGFloat(i) * 0.05)
                    }
                    
                    // 雷达扫描扇形
                    RadarSweep()
                        .fill(
                            AngularGradient(
                                colors: [.accentColor.opacity(0.4), .accentColor.opacity(0), .accentColor.opacity(0)],
                                center: .center
                            )
                        )
                        .frame(width: 280, height: 280)
                        .rotationEffect(.degrees(radarRotation))
                    
                    // 中心圆
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 80, height: 80)
                        .overlay {
                            VStack(spacing: 0) {
                                Text(bleDistanceText)
                                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                                    .foregroundColor(bleColor)
                                Text("米")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .shadow(color: .accentColor.opacity(0.3), radius: 15)
                    
                    // 周围的信号点
                    ForEach(Array(dotPositions.enumerated()), id: \.offset) { i, pos in
                        Circle()
                            .fill(bleColor)
                            .frame(width: 8, height: 8)
                            .offset(pos)
                            .opacity(0.6)
                    }
                }
                .frame(width: 280, height: 280)
                .padding(.vertical, 10)
                
                // 信号强度条
                VStack(spacing: 10) {
                    Text("信号强度")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(alignment: .bottom, spacing: 6) {
                        ForEach(0..<5, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(barColor(barIndex: i))
                                .frame(width: 16, height: CGFloat(12 + i * 10) * signalBars[i])
                        }
                    }
                    
                    Text(vm.bleDirection.rawValue == "cold" ? "信号弱 · 扩大搜索范围" :
                         vm.bleDirection.rawValue == "warm" ? "信号中等 · 正在接近" :
                         vm.bleDirection.rawValue == "hot" ? "信号强 · 就在附近" :
                         "已找到！")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(bleColor)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
                .padding(.horizontal, 40)
                
                // 扫描按钮
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        if vm.isScanning {
                            vm.stopScanning()
                        } else {
                            vm.startScanning()
                        }
                    }
                }) {
                    HStack(spacing: 10) {
                        Image(systemName: vm.isScanning ? "stop.circle.fill" : "play.circle.fill")
                            .font(.system(size: 22))
                        Text(vm.isScanning ? "停止搜索" : "开始搜索")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(vm.isScanning ? .red : .white)
                    .frame(width: 200, height: 52)
                    .background(
                        vm.isScanning ?
                        AnyShapeStyle(.ultraThinMaterial) :
                        AnyShapeStyle(LinearGradient(colors: [.blue, .accentColor], startPoint: .leading, endPoint: .trailing))
                    )
                    .clipShape(Capsule())
                    .shadow(color: vm.isScanning ? .clear : .accentColor.opacity(0.4), radius: 12)
                }
                
                // 提示文字
                if vm.isScanning {
                    VStack(spacing: 4) {
                        Text("距离越近信号越强")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("走到开阔地带扫描效果最佳")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 40)
            }
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            vm.stopScanning()
        }
        .onChange(of: vm.bleDirection) { _ in
            updateBars()
        }
    }
    
    // MARK: - 计算属性
    
    var bleDistanceText: String {
        guard let d = vm.bleDistance else { return "--" }
        return String(format: "%.1f", d)
    }
    
    var bleColor: Color {
        switch vm.bleDirection {
        case .cold:  return .gray
        case .warm:  return .orange
        case .hot:   return .red
        case .found: return .green
        }
    }
    
    func barColor(barIndex: Int) -> Color {
        let currentStrength = vm.bleDirection
        let threshold: ProximityDirection
        switch barIndex {
        case 0...1: threshold = .cold
        case 2:     threshold = .warm
        case 3:     threshold = .hot
        default:    threshold = .found
        }
        
        let dirs: [ProximityDirection] = [.cold, .warm, .hot, .found]
        let ci = dirs.firstIndex(of: currentStrength) ?? 0
        let ti = dirs.firstIndex(of: threshold) ?? 0
        return ci >= ti ? bleColor : .gray.opacity(0.3)
    }
    
    // MARK: - 动画
    
    func startAnimations() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            radarRotation = 360
        }
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
        
        // 模拟信号点
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            withAnimation {
                dotPositions = (0..<6).map { _ in
                    let angle = Double.random(in: 0...2 * .pi)
                    let radius = Double.random(in: 60...130)
                    return CGSize(
                        width: cos(angle) * radius,
                        height: sin(angle) * radius
                    )
                }
            }
        }
    }
    
    func updateBars() {
        withAnimation(.easeInOut(duration: 0.3)) {
            switch vm.bleDirection {
            case .cold:
                signalBars = [0.3, 0.15, 0.1, 0.05, 0.05]
            case .warm:
                signalBars = [0.6, 0.5, 0.3, 0.15, 0.05]
            case .hot:
                signalBars = [0.9, 0.8, 0.7, 0.5, 0.2]
            case .found:
                signalBars = [1.0, 1.0, 1.0, 1.0, 1.0]
            }
        }
    }
}

// MARK: - 雷达扫描扇形

struct RadarSweep: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(center: center, radius: rect.width / 2, startAngle: .degrees(-90), endAngle: .degrees(-30), clockwise: false)
        path.closeSubpath()
        return path
    }
}
