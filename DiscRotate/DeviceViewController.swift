//
//  DeviceViewController.swift
//  DiscRotate
//
//  Created by georg on 27.09.17.
//  Copyright © 2017 Georg Wacker. All rights reserved.
//

import Cocoa

let kDeviceDeactivatedAlpha : CGFloat = 0.4

class DeviceViewController : NSViewController
{
    @IBOutlet weak var deviceIcon: NSButton!
    @IBOutlet weak var deviceName: NSTextField!
    @IBOutlet weak var deviceSpeed: NSSegmentedControl!
    var observerActive : NSKeyValueObservation? = nil
    var observerSpeed : NSKeyValueObservation? = nil
    
    convenience init(_ device: MediaDevice)
    {
        self.init()
        self.representedObject = device
    }
    
    override func viewDidLoad() {
        //self.view.window?.makeKeyAndOrderFront(self)
        //self.view.window?.makeFirstResponder(deviceSpeed)
        
        let dev = representedObject as! MediaDevice
        
        let icon = NSWorkspace.shared.icon(forFileType: NSFileTypeForHFSTypeCode(OSType(kGenericCDROMIcon)))
        icon.size = NSMakeSize(32, 32)
        //NSGraphicsContext.current?.imageInterpolation = .none
        deviceIcon.image = icon
        
        deviceName.stringValue = dev.name
        
        if dev.userSpeed >= dev.speedTable.count {
            //deviceSpeed.selectedSegment = 0
            dev.userSpeed = 0
        }
        /*else {
            deviceSpeed.selectedSegment = dev.userSpeed
        }*/
        
        // clear all labels
        for i in 0..<deviceSpeed.segmentCount {
            deviceSpeed.setLabel("", forSegment: i)
        }
        
        // calculate and set labels to speed multipliers
        for (speed, index) in zip(dev.speedTable, 0..<deviceSpeed.segmentCount){
            let multi = Double(speed) / Double(dev.minSpeed)
            deviceSpeed.setLabel(String(format: "%.1fx", multi), forSegment: index)
        }
        
        // disable unused segments
        for i in 0..<deviceSpeed.segmentCount {
            if let label = deviceSpeed.label(forSegment: i), label == "" {
                deviceSpeed.setEnabled(false, forSegment: i)
            }
        }

        view.alphaValue = dev.active ? 1.0 : kDeviceDeactivatedAlpha
        
        observerActive = dev.observe(\.active) { object, change in
            self.view.animator().alphaValue = object.active ? 1.0 : kDeviceDeactivatedAlpha
            self.deviceSpeed.isEnabled = object.active
        }
        
        observerSpeed = dev.observe(\.userSpeed) { object, change in
            object.saveUserSpeed()
        }
        
        if(dev.unsupported)
        {
            deviceSpeed.selectedSegment = -1
            deviceSpeed.isEnabled = false
            deviceIcon.isEnabled = false
        }
    }
    
    // invalidate the observers in deinit instead of viewWillDisappear to keep them alive, even when the view is not shown
    deinit {
        observerActive = nil
        observerSpeed = nil
    }
    
}
