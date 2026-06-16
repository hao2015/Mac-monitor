import Foundation

struct DiskInfo {
    let totalGB: Double
    let freeGB: Double
    let usedPercent: Double
}

class DiskReader {
    func getDiskUsage() -> DiskInfo? {
        let path = NSHomeDirectory()
        do {
            let attributes = try FileManager.default.attributesOfFileSystem(forPath: path)
            if let totalSize = attributes[.systemSize] as? Int64,
               let freeSize = attributes[.systemFreeSize] as? Int64 {
                let totalGB = Double(totalSize) / 1_073_741_824.0
                let freeGB = Double(freeSize) / 1_073_741_824.0
                let usedGB = totalGB - freeGB
                let usedPercent = (usedGB / totalGB) * 100.0
                return DiskInfo(totalGB: totalGB, freeGB: freeGB, usedPercent: usedPercent)
            }
        } catch {
            print("Failed to read disk attributes: \(error)")
        }
        return nil
    }
}
