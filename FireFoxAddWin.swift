import Foundation
import Cocoa

// define
let leftMonitor = NSScreen.screens[1]
let rightMonitor = NSScreen.screens[2]
let leftMonitorSize  = leftMonitor.frame.size
let rightMonitorSize = rightMonitor.frame.size


class MoveWindow {
    var pid:pid_t?
    var appRef: AXUIElement?
    var value: AnyObject?
    
    func getPid() -> Bool {
        
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("Access Not Enabled")
        }
        
        
        let appPath = "/Applications/Firefox.app"
        let workspace = NSWorkspace()
        let conf = NSWorkspace.OpenConfiguration()
        
        workspace.openApplication(at: URL(fileURLWithPath: appPath), configuration: conf, completionHandler: nil)
        conf.createsNewApplicationInstance = true
        workspace.openApplication(at: URL(fileURLWithPath: appPath), configuration: conf, completionHandler: nil)


        let start = Date()
        // 起動するまで1秒おきに繰り返す、起動中はpidを入手できない
        while pid == nil {
            sleep(1)
            // 15秒でタイムアウト
            if Int(Date().timeIntervalSince(start)) > 15 {
                return false
            }
            let apps = NSWorkspace.shared.runningApplications
            
            for a in apps {
    //            print(a.bundleIdentifier)
                if a.executableURL?.lastPathComponent == "firefox" {
                    pid = a.processIdentifier
                    return true
                }
            }
        }
        return false
    }
    
    func move() {
        appRef = AXUIElementCreateApplication(pid!)
        AXUIElementCopyAttributeValue(appRef!, kAXWindowsAttribute as CFString, &value)
        
        let start = Date()
        
        // ウィンドウが立ち上がるまで時間がかかる
        while value == nil {
            AXUIElementCopyAttributeValue(appRef!, kAXWindowsAttribute as CFString, &value)
            sleep(1)
            // 15秒でタイムアウト
            if Int(Date().timeIntervalSince(start)) > 15 {
                return
            }
        }
        
        // ウィンドウが２つ立ち上がるまで繰り返す
        while (value!.count)! < 2 {
            sleep(1)
            AXUIElementCopyAttributeValue(appRef!, kAXWindowsAttribute as CFString, &value)
            // 15秒でタイムアウト
            if Int(Date().timeIntervalSince(start)) > 15 {
                print("強制終了")
                return
            }
        }
        
        // 立ち上がったウィンドウを移動する
        if let windowList = value as? [AXUIElement] {
            var position : CFTypeRef
            var size : CFTypeRef
            var  newPoint = rightMonitor.frame.origin //CGPoint(x: rightMonitorSize.width, y: 0)
            var newSize = rightMonitorSize

            for i in  0 ..< 2 {
            position = AXValueCreate(AXValueType(rawValue: kAXValueCGPointType)!,&newPoint)!;
                AXUIElementSetAttributeValue(windowList[i], kAXPositionAttribute as CFString, position);

            size = AXValueCreate(AXValueType(rawValue: kAXValueCGSizeType)!,&newSize)!;
                AXUIElementSetAttributeValue(windowList[i], kAXSizeAttribute as CFString, size);
                newPoint = leftMonitor.frame.origin //CGPoint(x: -leftMonitorSize.width, y: 0)
                newSize = leftMonitorSize
            }
        }
    }
}

var moveWindow:MoveWindow? = MoveWindow()

if moveWindow!.getPid() {
    moveWindow!.move()
}

moveWindow = nil
