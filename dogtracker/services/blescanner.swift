import Foundation
import CoreBluetooth

class BLEScanner: NSObject, ObservableObject, CBCentralManagerDelegate {
    @Published var rssi: Int? = nil
    @Published var isScanning: Bool = false
    
    private var centralManager: CBCentralManager!
    private var targetMAC: String?
    private var targetPeripheral: CBPeripheral?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning(for mac: String?) {
        targetMAC = mac
        guard centralManager.state == .poweredOn else { return }
        isScanning = true
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
        rssi = nil
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn && isScanning {
            central.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let target = targetMAC else {
            // 没指定目标，扫描所有设备
            self.rssi = RSSI.intValue
            return
        }
        
        // 匹配目标 MAC 地址
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
        let identifier = peripheral.identifier.uuidString
        
        if localName.contains(target) || identifier == target {
            self.rssi = RSSI.intValue
            targetPeripheral = peripheral
        }
    }
}
