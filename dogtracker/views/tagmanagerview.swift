import SwiftUI

struct TagManagerView: View {
    @EnvironmentObject var vm: DogTrackerViewModel
    @State private var selectedTag: DogTag?
    @State private var showAddSheet = false
    @State private var showUnpairAlert = false
    @State private var tagToUnpair: DogTag?
    @State private var showAppleIDAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // 标题
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tag 管理")
                            .font(.system(size: 28, weight: .bold))
                        Text("\(vm.dogs.count) 个设备")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.top, 60)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Apple ID 区域
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 20))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Find My 账户")
                                .font(.system(size: 15, weight: .semibold))
                            Text("需要 Apple ID 来查询 Tag 位置")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: vm.selectedDog != nil ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(vm.selectedDog != nil ? .green : .gray)
                    }
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                    .onTapGesture {
                        showAppleIDAlert = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
                
                // 已绑定的 Tag 列表
                VStack(alignment: .leading, spacing: 8) {
                    Text("已绑定的 Tag")
                        .font(.system(size: 16, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.bottom, 4)
                    
                    if vm.dogs.isEmpty {
                        EmptyTagPlaceholder()
                    } else {
                        ForEach(vm.dogs) { dog in
                            TagRow(dog: dog, isSelected: vm.selectedDog?.id == dog.id, onUnpair: {
                                tagToUnpair = dog
                                showUnpairAlert = true
                            })
                            .onTapGesture {
                                withAnimation { vm.selectedDog = dog }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
                
                // 添加按钮
                VStack(spacing: 12) {
                    Button(action: { showAddSheet = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 20))
                            Text("绑定新 Tag")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(colors: [.blue, .accentColor], startPoint: .leading, endPoint: .trailing),
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                    }
                    .padding(.horizontal, 16)
                    
                    // 解绑按钮
                    if !vm.dogs.isEmpty {
                        Button(action: {
                            tagToUnpair = vm.dogs.first
                            showUnpairAlert = true
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.circle")
                                    .font(.system(size: 18))
                                Text("解绑 Tag")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.red.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    Text("将 Tag 靠近手机即可自动发现\n支持 nRF52 OpenHaystack 兼容设备")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddTagSheet(isPresented: $showAddSheet)
        }
        .alert("解绑确认", isPresented: $showUnpairAlert, presenting: tagToUnpair) { tag in
            Button("取消", role: .cancel) {}
            Button("确认解绑", role: .destructive) {
                withAnimation {
                    vm.dogs.removeAll { $0.id == tag.id }
                    if vm.selectedDog?.id == tag.id {
                        vm.selectedDog = vm.dogs.first
                    }
                }
            }
        } message: { tag in
            Text("确定要解绑「\(tag.name)」吗？解绑后需要重新配对方可追踪。")
        }
    }
}

// MARK: - Tag 行

struct TagRow: View {
    let dog: DogTag
    let isSelected: Bool
    let onUnpair: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            ShibaAvatar(named: dog.name, size: 44, connected: dog.isConnected)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(dog.name)
                    .font(.system(size: 15, weight: .semibold))
                Text("MAC: \(dog.tagMAC)")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)
            }
            
            Button(action: onUnpair) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red.opacity(0.6))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(isSelected ? .green.opacity(0.3) : .clear, lineWidth: 1.5)
                )
        )
    }
}

// MARK: - 空状态

struct EmptyTagPlaceholder: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tag.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.4))
            Text("还没有绑定任何 Tag")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - 添加 Tag 弹窗

struct AddTagSheet: View {
    @EnvironmentObject var vm: DogTrackerViewModel
    @Binding var isPresented: Bool
    @State private var dogName = ""
    @State private var dogBreed = "柴犬"
    @State private var tagMAC = ""
    @State private var isScanning = false
    @State private var showPairedAlert = false
    
    let breeds = ["柴犬", "柯基", "金毛", "哈士奇", "泰迪", "比熊", "拉布拉多", "边牧", "其他"]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 狗子信息
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel("狗子信息")
                        
                        HStack {
                            Text("🐕")
                                .font(.system(size: 36))
                            VStack(spacing: 0) {
                                TextField("给狗子取个名", text: $dogName)
                                    .font(.system(size: 20, weight: .bold))
                                    .textContentType(.name)
                                Divider()
                                    .padding(.top, 6)
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        
                        // 品种选择
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(breeds, id: \.self) { breed in
                                    Button(action: { dogBreed = breed }) {
                                        Text(breed)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(dogBreed == breed ? .white : .secondary)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(
                                                dogBreed == breed ?
                                                AnyShapeStyle(Capsule().fill(.accentColor)) :
                                                AnyShapeStyle(Capsule().fill(.ultraThinMaterial))
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // Tag 信息
                    VStack(alignment: .leading, spacing: 12) {
                        SectionLabel("Tag 设备")
                        
                        // 自动扫描
                        Button(action: startAutoScan) {
                            HStack {
                                Image(systemName: isScanning ? "antenna.radiowaves.left.and.right" : "antenna.radiowaves.left.and.right.slash")
                                    .font(.system(size: 18))
                                    .foregroundColor(isScanning ? .blue : .secondary)
                                Text(isScanning ? "正在扫描附近的 Tag..." : "自动扫描 Tag")
                                    .font(.system(size: 14, weight: .medium))
                                Spacer()
                                if isScanning {
                                    ProgressView()
                                }
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // 或手动输入
                        VStack(spacing: 8) {
                            Text("或手动输入 MAC 地址")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            TextField("AA:BB:CC:DD:EE:FF", text: $tagMAC)
                                .font(.system(size: 15, design: .monospaced))
                                .textContentType(.none)
                                .autocapitalization(.allCharacters)
                                .multilineTextAlignment(.center)
                                .padding()
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer(minLength: 20)
                    
                    // 绑定按钮
                    Button(action: pairTag) {
                        HStack {
                            Image(systemName: "link")
                            Text("绑定 Tag")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            canPair ?
                            AnyShapeStyle(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)) :
                            AnyShapeStyle(LinearGradient(colors: [.gray, .gray], startPoint: .leading, endPoint: .trailing))
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canPair)
                    .padding(.horizontal, 16)
                }
                .padding(.top, 16)
            }
            .navigationTitle("绑定新 Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { isPresented = false }
                }
            }
        }
        .alert("✅ 配对成功", isPresented: $showPairedAlert) {
            Button("好的") { isPresented = false }
        } message: {
            Text("\(dogName) 已成功绑定！现在可以在 App 中追踪它了。")
        }
    }
    
    var canPair: Bool {
        !dogName.isEmpty && (!tagMAC.isEmpty || isScanning)
    }
    
    func startAutoScan() {
        isScanning = true
        // 模拟扫描 2 秒后发现设备
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            tagMAC = "AA:BB:CC:DD:EE:FF"
            isScanning = false
        }
    }
    
    func pairTag() {
        guard canPair else { return }
        
        let newDog = DogTag(
            id: UUID().uuidString,
            name: dogName,
            breed: dogBreed,
            tagMAC: tagMAC.isEmpty ? "自动扫描" : tagMAC,
            findMyID: "fm_\(UUID().uuidString.prefix(8))",
            lastLocation: nil,
            lastUpdate: nil,
            batteryLevel: 100,
            isConnected: true
        )
        
        vm.dogs.append(newDog)
        if vm.selectedDog == nil {
            vm.selectedDog = newDog
        }
        showPairedAlert = true
    }
}

// MARK: - 通用

struct SectionLabel: View {
    let _title: String
    init(_ title: String) { self._title = title }
    
    var body: some View {
        Text(_title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
    }
}
