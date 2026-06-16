import Foundation

struct DiskVolumeInfo {
    let name: String
    let path: String
    let isInternal: Bool
    let totalGB: Double
    let freeGB: Double
    let usedPercent: Double
}

class DiskReader {
    func getMountedVolumes() -> [DiskVolumeInfo] {
        var volumes: [DiskVolumeInfo] = []
        let keys: [URLResourceKey] = [
            .volumeNameKey,
            .volumeLocalizedNameKey,
            .volumeIsInternalKey,
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey
        ]
        
        // Retrieve all mounted volumes, skip hidden system-specific partitions
        guard let volumeURLs = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) else {
            return volumes
        }
        
        for url in volumeURLs {
            guard let resourceValues = try? url.resourceValues(forKeys: Set(keys)) else {
                continue
            }
            
            let name = resourceValues.volumeLocalizedName ?? resourceValues.volumeName ?? url.lastPathComponent
            let path = url.path
            let isInternal = resourceValues.volumeIsInternal ?? true
            
            if let totalSize = resourceValues.volumeTotalCapacity,
               let freeSize = resourceValues.volumeAvailableCapacity,
               totalSize > 0 {
                let totalGB = Double(totalSize) / 1_073_741_824.0
                let freeGB = Double(freeSize) / 1_073_741_824.0
                let usedGB = totalGB - freeGB
                let usedPercent = (usedGB / totalGB) * 100.0
                
                volumes.append(DiskVolumeInfo(
                    name: name,
                    path: path,
                    isInternal: isInternal,
                    totalGB: totalGB,
                    freeGB: freeGB,
                    usedPercent: usedPercent
                ))
            }
        }
        
        // Sort by path so the boot partition "/" is usually first
        return volumes.sorted { $0.path.count < $1.path.count }
    }
}
