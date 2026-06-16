import Foundation

class TemperatureReader {
    private var client: UnsafeMutableRawPointer?
    private var IOHIDEventSystemClientCreate: ((CFAllocator?) -> UnsafeMutableRawPointer?)?
    private var IOHIDEventSystemClientSetMatching: ((UnsafeMutableRawPointer?, CFDictionary?) -> Void)?
    private var IOHIDEventSystemClientCopyServices: ((UnsafeMutableRawPointer?) -> CFArray?)?
    private var IOHIDServiceClientCopyEvent: ((UnsafeMutableRawPointer?, UInt32, UInt32, UInt32) -> UnsafeMutableRawPointer?)?
    private var IOHIDEventGetFloatValue: ((UnsafeMutableRawPointer?, UInt32) -> Double)?
    private var IOHIDServiceClientCopyProperty: ((UnsafeMutableRawPointer?, CFString) -> CFTypeRef?)?
    
    init() {
        setupIOHID()
    }
    
    private func setupIOHID() {
        let handle = dlopen("/System/Library/Frameworks/IOKit.framework/Versions/Current/IOKit", RTLD_NOW)
        guard handle != nil else { return }
        
        typealias IOHIDEventSystemClientCreateType = @convention(c) (CFAllocator?) -> UnsafeMutableRawPointer?
        typealias IOHIDEventSystemClientSetMatchingType = @convention(c) (UnsafeMutableRawPointer?, CFDictionary?) -> Void
        typealias IOHIDEventSystemClientCopyServicesType = @convention(c) (UnsafeMutableRawPointer?) -> CFArray?
        typealias IOHIDServiceClientCopyEventExactType = @convention(c) (UnsafeMutableRawPointer?, UInt32, UInt32, UInt32) -> UnsafeMutableRawPointer?
        typealias IOHIDEventGetFloatValueType = @convention(c) (UnsafeMutableRawPointer?, UInt32) -> Double
        typealias IOHIDServiceClientCopyPropertyType = @convention(c) (UnsafeMutableRawPointer?, CFString) -> CFTypeRef?
        
        if let sym = dlsym(handle, "IOHIDEventSystemClientCreate") {
            IOHIDEventSystemClientCreate = unsafeBitCast(sym, to: IOHIDEventSystemClientCreateType.self)
        }
        if let sym = dlsym(handle, "IOHIDEventSystemClientSetMatching") {
            IOHIDEventSystemClientSetMatching = unsafeBitCast(sym, to: IOHIDEventSystemClientSetMatchingType.self)
        }
        if let sym = dlsym(handle, "IOHIDEventSystemClientCopyServices") {
            IOHIDEventSystemClientCopyServices = unsafeBitCast(sym, to: IOHIDEventSystemClientCopyServicesType.self)
        }
        if let sym = dlsym(handle, "IOHIDServiceClientCopyEvent") {
            IOHIDServiceClientCopyEvent = unsafeBitCast(sym, to: IOHIDServiceClientCopyEventExactType.self)
        }
        if let sym = dlsym(handle, "IOHIDEventGetFloatValue") {
            IOHIDEventGetFloatValue = unsafeBitCast(sym, to: IOHIDEventGetFloatValueType.self)
        }
        if let sym = dlsym(handle, "IOHIDServiceClientCopyProperty") {
            IOHIDServiceClientCopyProperty = unsafeBitCast(sym, to: IOHIDServiceClientCopyPropertyType.self)
        }
        
        if let createFn = IOHIDEventSystemClientCreate {
            client = createFn(kCFAllocatorDefault)
            if let clientPtr = client {
                let matchingDict: [String: Any] = [
                    "PrimaryUsagePage": 0xff00,
                    "PrimaryUsage": 5
                ]
                IOHIDEventSystemClientSetMatching?(clientPtr, matchingDict as CFDictionary)
            }
        }
    }
    
    func readCPUTemperature() -> Double? {
        guard let clientPtr = client,
              let copyServicesFn = IOHIDEventSystemClientCopyServices,
              let copyEventFn = IOHIDServiceClientCopyEvent,
              let getFloatValFn = IOHIDEventGetFloatValue else {
            return nil
        }
        
        guard let services = copyServicesFn(clientPtr) else { return nil }
        let count = CFArrayGetCount(services)
        
        var cpuTemps: [Double] = []
        
        for i in 0..<count {
            let service = CFArrayGetValueAtIndex(services, i)
            let servicePtr = UnsafeMutableRawPointer(mutating: service!)
            
            var name = "Unknown"
            if let copyPropFn = IOHIDServiceClientCopyProperty {
                if let productRef = copyPropFn(servicePtr, "Product" as CFString) {
                    name = productRef as? String ?? "\(productRef)"
                }
            }
            
            let nameLower = name.lowercased()
            // Track PMU tdie and tcal sensors for CPU Core temperatures
            if nameLower.contains("tdie") || nameLower.contains("pacc") || nameLower.contains("eacc") || nameLower.contains("tcal") {
                // kIOHIDEventTypeTemperature = 15
                if let event = copyEventFn(servicePtr, 15, 0, 0) {
                    // kIOHIDEventFieldTemperatureLevel = 983040 (15 << 16)
                    let temp = getFloatValFn(event, 983040)
                    if temp > 0 && temp < 150 {
                        cpuTemps.append(temp)
                    }
                    Unmanaged<AnyObject>.fromOpaque(event).release()
                }
            }
        }
        
        if cpuTemps.isEmpty {
            return nil
        }
        
        // Return peak CPU temperature
        return cpuTemps.max()
    }
    
    func readDiskTemperature() -> Double? {
        guard let clientPtr = client,
              let copyServicesFn = IOHIDEventSystemClientCopyServices,
              let copyEventFn = IOHIDServiceClientCopyEvent,
              let getFloatValFn = IOHIDEventGetFloatValue else {
            return nil
        }
        
        guard let services = copyServicesFn(clientPtr) else { return nil }
        let count = CFArrayGetCount(services)
        
        var nandTemps: [Double] = []
        
        for i in 0..<count {
            let service = CFArrayGetValueAtIndex(services, i)
            let servicePtr = UnsafeMutableRawPointer(mutating: service!)
            
            var name = "Unknown"
            if let copyPropFn = IOHIDServiceClientCopyProperty {
                if let productRef = copyPropFn(servicePtr, "Product" as CFString) {
                    name = productRef as? String ?? "\(productRef)"
                }
            }
            
            let nameLower = name.lowercased()
            // Track NAND temperature sensors for SSD/disk
            if nameLower.contains("nand") || nameLower.contains("ssd") || nameLower.contains("nvme") || nameLower.contains("storage") {
                // kIOHIDEventTypeTemperature = 15
                if let event = copyEventFn(servicePtr, 15, 0, 0) {
                    let temp = getFloatValFn(event, 983040)
                    if temp > 0 && temp < 150 {
                        nandTemps.append(temp)
                    }
                    Unmanaged<AnyObject>.fromOpaque(event).release()
                }
            }
        }
        
        if nandTemps.isEmpty {
            return nil
        }
        
        // Return peak NAND temperature
        return nandTemps.max()
    }
}
