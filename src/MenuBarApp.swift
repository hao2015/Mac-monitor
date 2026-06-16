import AppKit

class MenuBarApp: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let menu = NSMenu()
    private var timer: Timer?
    
    private let tempReader = TemperatureReader()
    private let cpuReader = CPUReader()
    private let diskReader = DiskReader()
    private let externalDiskReader = ExternalDiskReader()
    
    override init() {
        super.init()
        setupStatusItem()
        setupMenu()
        updateStatus()
        
        // Update every 2 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }
    
    private func setupStatusItem() {
        guard let button = statusItem.button else { return }
        
        // Configure native look and feel with SF Symbol
        if #available(macOS 11.0, *) {
            let config = NSImage.SymbolConfiguration(pointSize: 13.0, weight: .regular)
            if let image = NSImage(systemSymbolName: "thermometer.medium", accessibilityDescription: "Temperature")?
                .withSymbolConfiguration(config) {
                image.isTemplate = true // Ensures it adapts to light/dark mode automatically
                button.image = image
                button.imagePosition = .imageLeft
            }
        } else {
            button.title = "Temp: "
        }
    }
    
    private func setupMenu() {
        // CPU Temperature Item
        let tempItem = NSMenuItem(title: "CPU Temp: --°C", action: nil, keyEquivalent: "")
        tempItem.tag = 1
        if #available(macOS 11.0, *) {
            tempItem.image = NSImage(systemSymbolName: "thermometer", accessibilityDescription: "Temp")
        }
        menu.addItem(tempItem)
        
        // CPU Usage Item
        let cpuItem = NSMenuItem(title: "CPU Usage: --%", action: nil, keyEquivalent: "")
        cpuItem.tag = 2
        if #available(macOS 11.0, *) {
            cpuItem.image = NSImage(systemSymbolName: "cpu", accessibilityDescription: "CPU")
        }
        menu.addItem(cpuItem)
        
        // Disk Usage Item
        let diskItem = NSMenuItem(title: "Disk Usage: --%", action: nil, keyEquivalent: "")
        diskItem.tag = 3
        if #available(macOS 11.0, *) {
            diskItem.image = NSImage(systemSymbolName: "internaldrive", accessibilityDescription: "Disk")
        }
        menu.addItem(diskItem)
        
        // Disk Temperature Item
        let diskTempItem = NSMenuItem(title: "Disk Temp: --°C", action: nil, keyEquivalent: "")
        diskTempItem.tag = 4
        if #available(macOS 11.0, *) {
            diskTempItem.image = NSImage(systemSymbolName: "thermometer.snowflake", accessibilityDescription: "Disk Temp")
        }
        menu.addItem(diskTempItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit Item
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        if #available(macOS 11.0, *) {
            quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: "Quit")
        }
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
    
    private func updateStatus() {
        let temp = tempReader.readCPUTemperature()
        let diskTemp = tempReader.readDiskTemperature()
        let cpuUsage = cpuReader.getCPUUsage()
        let diskInfo = diskReader.getDiskUsage()
        
        // Update menu bar title
        if let button = statusItem.button {
            if let tempVal = temp {
                button.title = String(format: "%.0f°C", tempVal)
            } else {
                button.title = "--°C"
            }
        }
        
        // Update detailed CPU temp menu item
        if let tempItem = menu.item(withTag: 1) {
            if let tempVal = temp {
                tempItem.title = String(format: "CPU Temperature: %.1f °C", tempVal)
            } else {
                tempItem.title = "CPU Temperature: N/A"
            }
        }
        
        // Update detailed CPU usage menu item
        if let cpuItem = menu.item(withTag: 2) {
            cpuItem.title = String(format: "CPU Usage: %.1f%%", cpuUsage)
        }
        
        // Update detailed Disk usage menu item
        if let diskItem = menu.item(withTag: 3) {
            if let disk = diskInfo {
                diskItem.title = String(format: "Disk Used: %.1f%% (Free: %.1f GB / %.1f GB)", disk.usedPercent, disk.freeGB, disk.totalGB)
            } else {
                diskItem.title = "Disk Usage: N/A"
            }
        }
        
        // Update detailed Disk temp menu item
        if let diskTempItem = menu.item(withTag: 4) {
            if let tempVal = diskTemp {
                diskTempItem.title = String(format: "Disk Temperature: %.1f °C", tempVal)
            } else {
                diskTempItem.title = "Disk Temperature: N/A"
            }
        }
        
        // Update external disks dynamically
        while let existingItem = menu.item(withTag: 100) {
            menu.removeItem(existingItem)
        }
        
        let externalDisks = externalDiskReader.getExternalDisks()
        var separatorIndex = menu.numberOfItems - 2
        if separatorIndex < 0 { separatorIndex = 0 }
        
        for disk in externalDisks {
            let tempStr = disk.temperature != nil ? String(format: "%.1f °C", disk.temperature!) : "N/A"
            let itemTitle = "\(disk.modelName) (\(disk.devName)): \(tempStr)"
            let diskMenuItem = NSMenuItem(title: itemTitle, action: nil, keyEquivalent: "")
            diskMenuItem.tag = 100
            if #available(macOS 11.0, *) {
                diskMenuItem.image = NSImage(systemSymbolName: "externaldrive", accessibilityDescription: "External Disk")
            }
            menu.insertItem(diskMenuItem, at: separatorIndex)
            separatorIndex += 1
        }
    }
}
