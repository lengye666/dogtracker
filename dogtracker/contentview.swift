import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: DogTrackerViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // 自定义底部导航
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    MapTrackView()
                        .tag(0)
                    RadarView()
                        .tag(1)
                    HistoryView()
                        .tag(2)
                    TagManagerView()
                        .tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // 底部导航栏
                HStack(spacing: 0) {
                    TabBarButton(icon: "map.fill", label: "地图", isSelected: selectedTab == 0)
                        .onTapGesture { withAnimation { selectedTab = 0 } }
                    TabBarButton(icon: "dot.radiowaves.left.and.right", label: "雷达", isSelected: selectedTab == 1)
                        .onTapGesture { withAnimation { selectedTab = 1 } }
                    TabBarButton(icon: "clock.arrow.circlepath", label: "轨迹", isSelected: selectedTab == 2)
                        .onTapGesture { withAnimation { selectedTab = 2 } }
                    TabBarButton(icon: "tag.fill", label: "Tag", isSelected: selectedTab == 3)
                        .onTapGesture { withAnimation { selectedTab = 3 } }
                }
                .padding(.vertical, 8)
                .padding(.bottom, 20)
                .background(.ultraThinMaterial)
            }
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - TabBar 按钮

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(isSelected ? .accentColor : .gray)
            Text(label)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .accentColor : .gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Dog 状态卡片

struct DogStatusCard: View {
    @EnvironmentObject var vm: DogTrackerViewModel
    
    var body: some View {
        if let dog = vm.selectedDog {
            HStack(spacing: 14) {
                // 头像
                ShibaAvatar(named: dog.name, size: 46, connected: dog.isConnected)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(dog.name)
                        .font(.system(size: 17, weight: .bold))
                    Text("\(dog.breed) · \(dog.isConnected ? "已连接" : "离线")")
                        .font(.system(size: 12))
                        .foregroundColor(dog.isConnected ? .green : .gray)
                }
                
                Spacer()
                
                // 电池
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 4) {
                        Image(systemName: batteryIcon(level: dog.batteryLevel))
                            .font(.system(size: 12))
                        Text("\(dog.batteryLevel)%")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(batteryColor(level: dog.batteryLevel))
                    
                    if let time = vm.lastUpdateTime {
                        Text(timeAgo(time))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
            )
            .padding(.horizontal, 16)
        }
    }
    
    func batteryIcon(level: Int) -> String {
        switch level {
        case 0..<20: return "battery.0"
        case 20..<50: return "battery.25"
        case 50..<75: return "battery.50"
        case 75..<100: return "battery.75"
        default: return "battery.100"
        }
    }
    
    func batteryColor(level: Int) -> Color {
        level < 20 ? .red : level < 50 ? .orange : .green
    }
    
    func timeAgo(_ date: Date) -> String {
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 60 { return "刚刚" }
        if diff < 3600 { return "\(diff/60)分钟前" }
        return "\(diff/3600)小时前"
    }
}
