//
//  StatusMenuController.swift
//  DisplayBed
//
//  Created by Luca Attanasio on 16/08/2017.
//  Copyright © 2017 Luca Attanasio. All rights reserved.
//

import Cocoa
import CoreFoundation
import IOKit

class StatusMenuController: NSObject {
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var saveSettingsItem: NSMenuItem!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    let DisableMonitorPath = "/Applications/DisableMonitor.app/Contents/MacOS/DisableMonitor"
    let launchPath = "/bin/sh"
    
    var CURRENT_IDS_DISABLED = [Int]()  //KEEPS TRACK OF WHAT YOU ARE DOING AFTER START
    var STORED_IDS_DISABLED = [Int]()   //SETTINGS STORED WHEN CLICKING ON SAVE SETTINGS
    
    //var mouseLocation: CGPoint = .zero
    
    override func awakeFromNib() {
        //Building the menu on the status bar
        buildMenu()
        
        //Loading settings from last time it was opened
        loadSettings()
        
        //mouseMoving()
        
        //displays()
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(StatusMenuController.sleepListener(_:)), name: NSWorkspace.willSleepNotification, object: nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(StatusMenuController.sleepListener(_:)), name: NSWorkspace.didWakeNotification, object: nil)
    }

    @IBAction func quitClicked(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    @IBAction func screenEnableClicked(_ sender: NSMenuItem) {
        toggleSCREEN(ID: "--enable " + String(sender.tag))
        
        if(CURRENT_IDS_DISABLED.count != 0){
            for index in 0...CURRENT_IDS_DISABLED.count{
                if(sender.tag == CURRENT_IDS_DISABLED[index]){
                    CURRENT_IDS_DISABLED[index] = 0
                }
            }
        }
    }
    
    @IBAction func screenDisableClicked(_ sender: NSMenuItem) {
        if(numScreensConnected() > CURRENT_IDS_DISABLED.count + 1){
            toggleSCREEN(ID: "--disable " + String(sender.tag))
            if !(IDExists(ID: sender.tag)){
                CURRENT_IDS_DISABLED.append(sender.tag)
            }
        }
        else{
            print("One screen has to be connected")
        }
    }
    
    @IBAction func saveSettings(_ sender: NSMenuItem){
        saveSettings()
        sender.isEnabled = false
    }
    
    @IBAction func resetSettings(_ sender: NSMenuItem) {
        let userDefaults = UserDefaults.standard
        
        STORED_IDS_DISABLED = [Int]()
        
        // Save Settings
        userDefaults.set(STORED_IDS_DISABLED, forKey: "key")
        saveSettingsItem.isEnabled = true
        
        print("reset settings")
    }
    
    @IBAction func goDark(_ sender: Any) {
        setBrightness(level: 0.0)
        //display_sleep() //both screens go to sleep
    }
    
    @objc func sleepListener(_ aNotification : NSNotification) {
        if aNotification.name == NSWorkspace.willSleepNotification{
            print("Going to sleep")
        }
        else if aNotification.name == NSWorkspace.didWakeNotification{
            print("Woke up")
            disableIDS(IDS: CURRENT_IDS_DISABLED)
        }
    }
    
    //Custom functions
    func buildMenu(){
        print("building menu")
        statusItem.title = ""
        statusItem.menu = statusMenu
        
        let icon = NSImage(named: NSImage.Name(rawValue: "statusIcon"))
        icon?.isTemplate = true
        statusItem.image = icon
        statusItem.menu = statusMenu
        
        let list = getList()
        //print(list.count)
        for index in stride(from: list.count - 1, to: 0, by: -2) {
            let itemScreenName = NSMenuItem()
            itemScreenName.title = list[index]
            itemScreenName.isEnabled = false
            
            let itemEnable = NSMenuItem(title:"Enable", action:#selector(StatusMenuController.screenEnableClicked(_:)), keyEquivalent:"")
            let itemDisable = NSMenuItem(title:"Disable", action:#selector(StatusMenuController.screenDisableClicked(_:)), keyEquivalent:"")
            
            itemEnable.target = self
            itemDisable.target = self
            
            if let ID = Int(list[index - 1]) {
                itemEnable.tag = ID
                itemDisable.tag = ID
            }
            
            statusMenu.insertItem(itemDisable, at: 0)
            statusMenu.insertItem(itemEnable, at: 0)
            statusMenu.insertItem(itemScreenName, at: 0)
        }

    }
    
    func getList() -> [String] {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = ["-c", DisableMonitorPath + " --list"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        var list = [String]()
        
        if let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            
            var lines: [String] = []
            output.enumerateLines { line, _ in
                lines.append(line)
            }
            //0, 1, N - 1 NOT USED
            for index in 2...(lines.count - 2){
                let SCREEN = lines[index].components(separatedBy: " ")
                
                let SCREEN_ID = SCREEN[1]
                list.append(SCREEN_ID)
                
                if(SCREEN[2] == ""){
                    let SCREEN_NAME = "Color LCD"
                    list.append(SCREEN_NAME)
                }
                else{
                    let SCREEN_NAME = SCREEN[2] + " " + SCREEN[3]
                    list.append(SCREEN_NAME)
                }
                
            }
            print(list)
        }
        
        task.waitUntilExit()
        return list
    }
    
    //functions for screen IDS
    //toggles screen on and off
    func toggleSCREEN(ID: String) {
        let task = Process()
        task.launchPath = launchPath
        task.arguments = ["-c", DisableMonitorPath + " " + ID]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        task.waitUntilExit()
    }
    
    //disables ids of given array
    func disableIDS(IDS: [Int]){
        if(numScreensConnected() > IDS.count + 1){
            for index in 0...IDS.count{
                toggleSCREEN(ID: "--disable " + String(IDS[index]))
            }
        }
    }
    
    //counts the number of screens connected at the moment by using DisableMonitor
    func numScreensConnected() -> Int{
        var n = 0
        let task = Process()
        task.launchPath = launchPath
        task.arguments = ["-c", DisableMonitorPath + " --list"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        
        if let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
            var lines: [String] = []
            output.enumerateLines { line, _ in
                lines.append(line)
            }
        
            n = lines.count - 3
            print("numScreensConnected: " + String(n))
        }
        
        task.waitUntilExit()
        return n
    }
    
    func IDExists(ID: Int) -> Bool{
        for index in 0...CURRENT_IDS_DISABLED.count - 1{
            if(CURRENT_IDS_DISABLED[index] == ID){
                return true
            }
        }
        return false
    }
    
    //Functions for settings
    func loadSettings(){
        let userDefaults = UserDefaults.standard
        
        if let userSettings = userDefaults.object(forKey: "key") {
            STORED_IDS_DISABLED = userSettings as! [Int]
            disableIDS(IDS: STORED_IDS_DISABLED)
            
            print("loading settings")
            print(userSettings)
        }
        
        CURRENT_IDS_DISABLED = STORED_IDS_DISABLED
    }
    
    func saveSettings(){
        let userDefaults = UserDefaults.standard
        
        userDefaults.set(CURRENT_IDS_DISABLED, forKey: "key")
        print("saving settings")
        print(CURRENT_IDS_DISABLED)
    }
    
    private func setBrightness(level: Float) {
        let service = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IODisplayConnect"))
        
        IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, level)
        IOObjectRelease(service)
    }
    
    /*
     //still not completed, doesn't work as it should
     func mouseMoving(){
        
        
        
        /*NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) {
            self.mouseLocation = NSEvent.mouseLocation()
            //print(String(format: "%.8f, %.8f", self.mouseLocation.x, self.mouseLocation.y))
            let xLimit: CGFloat = 1919.99609376
            if(self.mouseLocation.x >= xLimit){
                
                let yLimit: CGFloat = 1080.00000000
                
                var point = NSEvent.mouseLocation()
                point.x = xLimit
                point.y = yLimit-point.y
                print(String(format: "%.8f, %.8f", point.x, point.y))
                //CGWarpMouseCursorPosition(point)
            }
            
            let x = CGGetLastMouseDelta().x
            let y = CGGetLastMouseDelta().y
            print(String(x) +  " " + String(y))
            
            return $0
        }*/
        
        NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { _ in
            self.mouseLocation = NSEvent.mouseLocation()
            //print(String(format: "%.8f, %.8f", self.mouseLocation.x, self.mouseLocation.y))
            let xLimit: CGFloat = 1919.99609376
            if(self.mouseLocation.x >= xLimit){
                
                CGAssociateMouseAndMouseCursorPosition(boolean_t(false))
                let yLimit: CGFloat = 1080.00000000
                
                var point = NSEvent.mouseLocation()
                point.x = xLimit
                point.y = yLimit-point.y
                print(String(format: "%.8f, %.8f", point.x, point.y))
                CGWarpMouseCursorPosition(point)
                
                //block form 1920x1080 to 1920x0
            }
        }

    }
    
    //still not completed, doesn't work as it should
    func displays(){
        let maxDisplays: UInt32 = 16
        //var onlineDisplays = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
        let onlineDisplays = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: Int(maxDisplays))
        let displayCount = UnsafeMutablePointer<UInt32>.allocate(capacity: 0)
        let dErr = CGGetOnlineDisplayList(maxDisplays, onlineDisplays, displayCount)
        
        for index in 0...displayCount.pointee{
            print(onlineDisplays[Int(index)])
        }
        print(dErr)
    }
    
    //still not completed, doesn't work as it should
    func display_sleep(){
        usleep(1000*1000); // sleep 1000 ms
        
        let config = UnsafeMutablePointer<CGDisplayConfigRef?>.allocate(capacity: 1) //1 configurazione
        
        var err = CGBeginDisplayConfiguration(config)
        
        err = CGBeginDisplayConfiguration(config)
        
        print(err)
        
        CGConfigureDisplayFadeEffect(config[0], 0, 0, 0, 0, 0)
        
        let reg: io_registry_entry_t = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/IOResources/IODisplayWrangler")
        
        IORegistryEntrySetCFProperty(reg, "IORequestIdle" as CFString, kCFBooleanTrue)
        usleep(100*1000); // sleep 100 ms
        IORegistryEntrySetCFProperty(reg, "IORequestIdle" as CFString, kCFBooleanFalse);    //second screen blinks
        IOObjectRelease(reg)
        
        let option = CGConfigureOption.permanently
        err = CGCompleteDisplayConfiguration(config[0], option)
    }*/
    
}
