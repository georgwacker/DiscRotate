//
//  OpticalMediaDetector.swift
//  DiscRotate
//
//  Created by georg on 07.09.17.
//  Copyright © 2017 Georg Wacker. All rights reserved.
//
import Cocoa
import Foundation
import IOKit.storage

@objcMembers
class OpticalMediaDetector : NSObject
{
    static let shared = OpticalMediaDetector()
    //let appd = NSApplication.shared.delegate as! AppDelegate
    
    dynamic var devices = [MediaDevice]()
    
    let notifyQueue: DispatchQueue
    let callbackQueue: DispatchQueue
    
    enum EventType {
        case Matched
        case Terminated
    }
    
    var throttleTimer = Timer()
    
    let notifyPort: IONotificationPortRef
    var matchCD: io_iterator_t = 0
    var termCD: io_iterator_t = 0
    
    var matchDVD: io_iterator_t = 0
    var termDVD: io_iterator_t = 0
    
    var matchBD: io_iterator_t = 0
    var termBD: io_iterator_t = 0
    
    func matchEvent(_ ioService: io_iterator_t){   
        guard let mediaName = ioService.name() else { return }
        
        let bsdName = IORegistryEntryCreateCFProperty(ioService, kIOBSDNameKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as! String
        
        var mediaType = IORegistryEntryCreateCFProperty(ioService, kIOCDMediaTypeKey as CFString, kCFAllocatorDefault, 0).takeRetainedValue() as! String
        mediaType = String(mediaType.split(separator: "-")[0])
        
        let group = DispatchGroup()
        group.enter()
        
        let md = MediaDevice(name: mediaName, path: "/dev/r" + bsdName, type: mediaType)
        
        // wait 2s for the drive to settle, otherwise read errors might occur
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 2){
            md.loadSettingsOrMakeDefaults()
            group.leave()
        }
        group.wait()
        devices.append(md)
        DispatchQueue.main.sync { ViewController.shared.addDevice(md) }
        
        print("added: " + md.debugDescription)
    }
    
    func terminatedEvent(_ ioService: io_iterator_t){
        guard let mediaName = ioService.name() else { return }
        
        if let i = devices.index(where: { $0.name == mediaName }) {
            let removed = devices.remove(at: i)
            print("removed: " + removed.debugDescription)
        }
        
        DispatchQueue.main.sync { ViewController.shared.removeDevice(mediaName) }
    }
    
    func dispatchEvent(type: EventType, iterator: io_iterator_t){
        while case let ioService = IOIteratorNext(iterator), ioService != 0 {
            callbackQueue.async {
                if type == .Matched { self.matchEvent(ioService) }
                else { self.terminatedEvent(ioService) }
                IOObjectRelease(ioService)
            }
        }
    }
   
    override init() {
        notifyQueue = DispatchQueue(label: "com.georgwacker.discrotate.notifyQueue")
        callbackQueue = DispatchQueue.global()
        
        notifyPort = IONotificationPortCreate(kIOMasterPortDefault)
        IONotificationPortSetDispatchQueue(notifyPort, notifyQueue)
        
    }
    
    deinit {
        throttleTimer.invalidate()
        IOObjectRelease(matchCD)
        IOObjectRelease(termCD)
        
        IOObjectRelease(matchDVD)
        IOObjectRelease(termDVD)
        
        IOObjectRelease(matchBD)
        IOObjectRelease(termBD)
        IONotificationPortDestroy(notifyPort)
    }
    
    func throttleTimerBlock(_ timer: Timer){
        for device in self.devices {
            device.throttle()
        }
    }
    
    func start(){
        
        if #available(OSX 10.12, *) {
            throttleTimer = Timer.init(timeInterval: 3, repeats: true){ timer in
                for device in self.devices {
                    device.throttle()
                }
            }
        } else {
            throttleTimer = Timer.init(timeInterval: 3, target: self, selector: #selector(throttleTimerBlock), userInfo: nil, repeats: true)
        }
        
        // manually add the timer to the runloop to set the runmode, which will allow the timer to fire while the menu is open
        RunLoop.current.add(throttleTimer, forMode: .commonModes)

        // Sadly, we can't match on several "IOProviderClass" : ["IOCDMedia", "IODVDMedia", "IOBDMedia"] ]
        // nor on several kIOCDMediaTypeKey : ["DVD-ROM", "CD-ROM"]
        
        let matchDictCD = IOServiceMatching(kIOCDMediaClass) as NSMutableDictionary
        matchDictCD[kIOMediaEjectableKey] = true
        
        let matchDictDVD = IOServiceMatching(kIODVDMediaClass) as NSMutableDictionary
        matchDictDVD[kIOMediaEjectableKey] = true
        
        let matchDictBD = IOServiceMatching(kIOBDMediaClass) as NSMutableDictionary
        matchDictBD[kIOMediaEjectableKey] = true
        
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        
        let matchCallback: IOServiceMatchingCallback = { (refcon, iterator) in
            let detector = Unmanaged<OpticalMediaDetector>.fromOpaque(refcon!).takeUnretainedValue()
            detector.dispatchEvent(type: .Matched, iterator: iterator)
        }
        
        let terminatedCallback: IOServiceMatchingCallback = { (refcon, iterator) in
            let detector = Unmanaged<OpticalMediaDetector>.fromOpaque(refcon!).takeUnretainedValue()
            detector.dispatchEvent(type: .Terminated, iterator: iterator)
        }
        
        IOServiceAddMatchingNotification(notifyPort, kIOFirstMatchNotification, matchDictCD, matchCallback, selfPtr, &matchCD)
        IOServiceAddMatchingNotification(notifyPort, kIOFirstMatchNotification, matchDictDVD, matchCallback, selfPtr, &matchDVD)
        IOServiceAddMatchingNotification(notifyPort, kIOFirstMatchNotification, matchDictBD, matchCallback, selfPtr, &matchBD)
        
        IOServiceAddMatchingNotification(notifyPort, kIOTerminatedNotification, matchDictCD, terminatedCallback, selfPtr, &termCD)
        IOServiceAddMatchingNotification(notifyPort, kIOTerminatedNotification, matchDictDVD, terminatedCallback, selfPtr, &termDVD)
        IOServiceAddMatchingNotification(notifyPort, kIOTerminatedNotification, matchDictBD, terminatedCallback, selfPtr, &termBD)
        
        // arming io_iterator callbacks
        dispatchEvent(type: .Matched, iterator: matchCD)
        dispatchEvent(type: .Terminated, iterator: termCD)
        
        dispatchEvent(type: .Matched, iterator: matchDVD)
        dispatchEvent(type: .Terminated, iterator: termDVD)
        
        dispatchEvent(type: .Matched, iterator: matchBD)
        dispatchEvent(type: .Terminated, iterator: termBD)
    }
    
}

extension io_object_t {
    func name() -> String? {
        var ioMediaName: [CChar] = [CChar](repeating: 0, count: 128)
        if IORegistryEntryGetName(self, &ioMediaName) == KERN_SUCCESS {
            return String(cString: ioMediaName)
        }
        return nil
    }
}
