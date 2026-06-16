import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarApp: MenuBarApp?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarApp = MenuBarApp()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
