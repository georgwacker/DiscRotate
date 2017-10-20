//
//  AppDelegate.swift
//  DiscRotateHelper
//
//  Created by georg on 20.10.17.
//  Copyright © 2017 Georg Wacker. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let path = Bundle.main.bundlePath as NSString
        var comp = path.pathComponents
        comp.removeLast(3)
        comp.append("MacOS")
        comp.append("DiscRotate")
        let newPath = NSString.path(withComponents: comp)
        NSWorkspace.shared.launchApplication(newPath)
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}

