import Foundation

class CPUReader {
    private var prevCpuInfo: host_cpu_load_info = host_cpu_load_info()
    private var hasPrevCpuInfo = false
    
    func getCPUUsage() -> Double {
        var size = mach_msg_type_number_t(MemoryLayout<host_cpu_load_info>.size / MemoryLayout<integer_t>.size)
        var cpuInfo = host_cpu_load_info()
        
        let result = withUnsafeMutablePointer(to: &cpuInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &size)
            }
        }
        
        if result != KERN_SUCCESS {
            return 0.0
        }
        
        if !hasPrevCpuInfo {
            prevCpuInfo = cpuInfo
            hasPrevCpuInfo = true
            return 0.0
        }
        
        let userDiff = Double(cpuInfo.cpu_ticks.0 - prevCpuInfo.cpu_ticks.0)
        let systemDiff = Double(cpuInfo.cpu_ticks.1 - prevCpuInfo.cpu_ticks.1)
        let idleDiff = Double(cpuInfo.cpu_ticks.2 - prevCpuInfo.cpu_ticks.2)
        let niceDiff = Double(cpuInfo.cpu_ticks.3 - prevCpuInfo.cpu_ticks.3)
        
        let total = userDiff + systemDiff + idleDiff + niceDiff
        prevCpuInfo = cpuInfo
        
        if total == 0 {
            return 0.0
        }
        
        return (userDiff + systemDiff + niceDiff) / total * 100.0
    }
}
