//
//  AppDelegate.swift
//  DiscRotate
//
//  Created by georg on 19/09/16.
//  Copyright © 2017 Georg Wacker. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var monitor: Any?
    let popover = NSPopover()
    
    @objc func toggleView(_ sender: Any?){
        if popover.isShown {
            popover.performClose(sender)
        }
        else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        //UserDefaults.standard.register(defaults: ["LaunchAtLogin" : true])
        //print(Array(UserDefaults.standard.dictionaryRepresentation()))
        
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]){ event in
            if self.popover.isShown {
                self.popover.performClose(event)
            }
        }
        
        if let button = statusItem.button {
            button.image = NSImage(named: NSImage.Name(rawValue: "DiscRotate"))
            button.imageScaling = .scaleProportionallyUpOrDown
            button.action = #selector(toggleView)
        }
        
        popover.appearance = NSAppearance(named: .vibrantLight)
        popover.contentViewController = ViewController.shared
        popover.animates = false
        
        //DispatchQueue.global(qos: .utility).async {
            OpticalMediaDetector.shared.start()
        //}
        
        /*observer = OpticalMediaDetector.shared.observe(\.devices){ object, change in
            print(change)
        }

        deviceProxy = OpticalMediaDetector.shared.mutableArrayValue(forKeyPath: #keyPath(OpticalMediaDetector.devices))
        
        /*observer = self.observe(\AppDelegate.deviceProxy) { object, change in
            print(change)
        }*/
        
        observer = self.observe(\AppDelegate.deviceProxy) { object, change in
            print(change)
        }*/

    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if let clickMonitor = monitor {
            NSEvent.removeMonitor(clickMonitor)
        }
        UserDefaults.standard.synchronize()
    }

}

