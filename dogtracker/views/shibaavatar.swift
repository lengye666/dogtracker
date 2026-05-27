import SwiftUI

// MARK: - 柴犬头像组件

struct ShibaAvatar: View {
    let name: String
    let size: CGFloat
    let isConnected: Bool
    
    init(named name: String, size: CGFloat = 48, connected: Bool = true) {
        self.name = name
        self.size = size
        self.isConnected = connected
    }
    
    var body: some View {
        ZStack {
            // 外层渐变圆环
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.orange, Color(red: 0.9, green: 0.4, blue: 0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size + 2, height: size + 2)
            
            // 头像
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.98, green: 0.85, blue: 0.65), Color(red: 0.95, green: 0.7, blue: 0.4)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: size, height: size)
                
                // 柴犬五官（纯 SwiftUI 绘制）
                ShibaFace(size: size)
            }
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 2)
            )
            
            // 连线状态指示灯
            if isConnected {
                Circle()
                    .fill(.green)
                    .frame(width: size * 0.28, height: size * 0.28)
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 1.5)
                    )
                    .offset(x: size * 0.35, y: size * 0.35)
            }
        }
        .shadow(color: .orange.opacity(0.25), radius: 6)
    }
}

// MARK: - 纯代码画柴犬脸

struct ShibaFace: View {
    let size: CGFloat
    
    var scale: CGFloat { size / 50 }
    
    var body: some View {
        ZStack {
            // 白色面部
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.white, Color(red: 0.96, green: 0.94, blue: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.72, height: size * 0.65)
                .offset(y: size * 0.08)
            
            // 眼睛
            HStack(spacing: size * 0.3) {
                // 左眼
                ZStack {
                    Ellipse()
                        .fill(.black)
                        .frame(width: size * 0.1, height: size * 0.13)
                    Circle()
                        .fill(.white)
                        .frame(width: size * 0.04, height: size * 0.04)
                        .offset(x: size * 0.015, y: -size * 0.02)
                }
                // 右眼
                ZStack {
                    Ellipse()
                        .fill(.black)
                        .frame(width: size * 0.1, height: size * 0.13)
                    Circle()
                        .fill(.white)
                        .frame(width: size * 0.04, height: size * 0.04)
                        .offset(x: size * 0.015, y: -size * 0.02)
                }
            }
            .offset(y: -size * 0.02)
            
            // 鼻子
            RoundedRectangle(cornerRadius: size * 0.05)
                .fill(.black)
                .frame(width: size * 0.18, height: size * 0.1)
                .offset(y: size * 0.1)
            
            // 嘴巴
            VStack(spacing: 0) {
                HStack {}
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addQuadCurve(
                        to: CGPoint(x: size * 0.06, y: size * 0.06),
                        control: CGPoint(x: size * 0.03, y: 0)
                    )
                }
                .stroke(.black, lineWidth: 1.5)
                .frame(width: size * 0.12, height: size * 0.08)
            }
            .offset(y: size * 0.18)
        }
    }
}

// MARK: - 狗子照片头像（可选替换）

struct DogPhotoAvatar: View {
    let imageName: String
    let size: CGFloat
    let isConnected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(.orange.opacity(0.3))
                .frame(width: size + 4, height: size + 4)
            
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
            
            if isConnected {
                Circle()
                    .fill(.green)
                    .frame(width: size * 0.25, height: size * 0.25)
                    .overlay(Circle().stroke(.white, lineWidth: 1.5))
                    .offset(x: size * 0.33, y: size * 0.33)
            }
        }
    }
}

// MARK: - 预览

struct ShibaAvatar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            ShibaAvatar(named: "小八", size: 80)
            ShibaAvatar(named: "豆豆", size: 48)
            ShibaAvatar(named: "团子", size: 32, connected: false)
        }
        .padding()
        .preferredColorScheme(.dark)
        .background(Color(red: 0.04, green: 0, blue: 0.08))
    }
}
