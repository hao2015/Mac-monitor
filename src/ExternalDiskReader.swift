import Foundation

struct ExternalDiskInfo {
    let devName: String     // e.g. "disk1"
    let modelName: String   // e.g. "Samsung SSD T7"
    let temperature: Double?
}

class ExternalDiskReader {
    private let smartctlPaths = [
        "/opt/homebrew/bin/smartctl",
        "/usr/local/bin/smartctl",
        "/usr/bin/smartctl"
    ]
    
    private var activeSmartctlPath: String? {
        for path in smartctlPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        return nil
    }
    
    private func runCommand(path: String, arguments: [String]) -> String? {
        let process = Process()
        process.launchPath = path
        process.arguments = arguments
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        
        process.launch()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8)
    }
    
    // Find all external physical disks
    func getExternalDisks() -> [ExternalDiskInfo] {
        var disks: [ExternalDiskInfo] = []
        
        // 1. Get all disks via diskutil list -plist
        guard let listOutput = runCommand(path: "/usr/sbin/diskutil", arguments: ["list", "-plist"]),
              let listData = listOutput.data(using: .utf8) else {
            return disks
        }
        
        guard let plist = try? PropertyListSerialization.propertyList(from: listData, options: [], format: nil) as? [String: Any],
              let allDisks = plist["AllDisks"] as? [String] else {
            return disks
        }
        
        // Filter parent whole disks (e.g. "disk1", not "disk1s1")
        let wholeDisks = allDisks.filter { !$0.contains("s") }
        
        for disk in wholeDisks {
            // Query details for each disk
            guard let infoOutput = runCommand(path: "/usr/sbin/diskutil", arguments: ["info", "-plist", disk]),
                  let infoData = infoOutput.data(using: .utf8) else {
                continue
            }
            
            guard let infoPlist = try? PropertyListSerialization.propertyList(from: infoData, options: [], format: nil) as? [String: Any] else {
                continue
            }
            
            // We want physical external disks
            let isInternal = infoPlist["Internal"] as? Bool ?? true
            let isVirtual = infoPlist["VirtualOrPhysical"] as? String == "Virtual"
            
            if !isInternal && !isVirtual {
                let model = infoPlist["MediaName"] as? String ?? "External Disk"
                let temp = getDiskTemperature(devName: disk)
                disks.append(ExternalDiskInfo(devName: disk, modelName: model, temperature: temp))
            }
        }
        
        return disks
    }
    
    // Query temperature of a disk via sudo smartctl
    private func getDiskTemperature(devName: String) -> Double? {
        guard let smartPath = activeSmartctlPath else {
            return nil // smartctl is not installed
        }
        
        // Execute sudo smartctl -j -a /dev/diskX
        let devPath = "/dev/\(devName)"
        guard let output = runCommand(path: "/usr/bin/sudo", arguments: [smartPath, "-j", "-a", devPath]),
              let data = output.data(using: .utf8) else {
            return nil
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            return nil
        }
        
        // 1. Try to read normalized temperature object (supported by smartctl 7.0+)
        if let tempDict = json["temperature"] as? [String: Any],
           let current = tempDict["current"] as? Double {
            return current
        }
        
        // 2. Try NVMe specific log fallback
        if let nvmeLog = json["nvme_smart_health_information_log"] as? [String: Any],
           let current = nvmeLog["temperature"] as? Double {
            return current
        }
        
        // 3. Try ATA attributes table fallback (SATA)
        if let ataTable = json["ata_smart_attributes"] as? [String: Any],
           let table = ataTable["table"] as? [[String: Any]] {
            for attribute in table {
                if let id = attribute["id"] as? Int, (id == 194 || id == 190) { // Temperature_Celsius or Airflow_Temperature_Cel
                    if let rawDict = attribute["raw"] as? [String: Any],
                       let value = rawDict["value"] as? Double {
                        return value
                    }
                }
            }
        }
        
        return nil
    }
}
