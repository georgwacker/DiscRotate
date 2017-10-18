//
//  MediaDevice.swift
//  DiscRotate
//
//  Created by georg on 09.09.17.
//  Copyright © 2017 Georg Wacker. All rights reserved.
//

import Foundation
import IOKit
import IOKit.storage

//let kCDSpeedMin : UInt16 = 0x00B0 // IOKit > storage > IOCDTypes.h
//let kBDSpeedMax : UInt16 = 0xFFFF // IOKit > storage > IOBDTypes.h

@objcMembers
class MediaDevice : NSObject {
    
    dynamic let name, path, type : String
    
    var userSpeed: Int = 0 {
        didSet {
            /*if userSpeed != oldValue {
                saveUserSpeed()
            }*/
        }
    }
    
    var minSpeed = 0
    var maxSpeed = 0
    var speedTable = [Int]()
    
    dynamic var active = true {
        didSet{
            // device has been disabled, new state is false
            if active == false {
                DispatchQueue.global(qos: .utility).async {
                    Drive.setSpeed(UInt16(kBDSpeedMax), forPath: self.path, withType: self.type)
                    //print("speed is now: " + Drive.getSpeedForPath(self.path, withType: self.type).stringValue)
                }
            }
        }
    }
    
    var unsupported = false
    
    override var debugDescription: String {
        return name + " (" + type + ")"
    }
    
    init(name: String, path: String, type: String) {
        self.name = name
        self.path = path
        self.type = type
    }
    
    func sweepDriveSpeed() -> [Int] {
        var table = [minSpeed]
        for speed in stride(from: minSpeed, through: maxSpeed + 10, by: 10){
            Drive.setSpeed(UInt16(speed), forPath: path, withType: type)
            let testSpeed = Drive.getSpeedForPath(path, withType: type) as! Int
            
            if testSpeed > table.last! {
                table.append(testSpeed)
            }
        }
        return table
    }
    
    func saveUserSpeed() {
        if var dictDevice = UserDefaults.standard.dictionary(forKey: self.name) as? [String : [ String : Any] ] {
            if let _ = dictDevice[self.type]?.updateValue(userSpeed, forKey: "userSpeed"){
                UserDefaults.standard.set(dictDevice, forKey: self.name)
            }
        }
    }
    
    func loadSettingsOrMakeDefaults(){
        
        var dictDevice = UserDefaults.standard.dictionary(forKey: self.name) as? [String : [ String : Any] ] ?? [String:[String:Any]]()
        
        if let dictType = dictDevice[self.type]{
            
            speedTable = dictType["speedTable"] as! [Int]
            userSpeed = dictType["userSpeed"] as! Int
            minSpeed = dictType["minSpeed"] as! Int
            maxSpeed = dictType["maxSpeed"] as! Int
            if minSpeed == maxSpeed { unsupported = true }
            
        } else {
            // media type for this device not set yet
            var dictTypeNew = [String:Any]()
            
            Drive.setSpeed(UInt16(kBDSpeedMax), forPath: self.path, withType: self.type)
            maxSpeed = Drive.getSpeedForPath(self.path, withType: self.type) as! Int
            
            Drive.setSpeed(UInt16(kCDSpeedMin), forPath: self.path, withType: self.type)
            minSpeed = Drive.getSpeedForPath(self.path, withType: self.type) as! Int
            
            speedTable = sweepDriveSpeed()
            userSpeed = 0
            dictTypeNew.updateValue(speedTable, forKey: "speedTable")
            dictTypeNew.updateValue(userSpeed, forKey: "userSpeed")
            dictTypeNew.updateValue(minSpeed, forKey: "minSpeed")
            dictTypeNew.updateValue(maxSpeed, forKey: "maxSpeed")
            
            dictDevice.updateValue(dictTypeNew, forKey: self.type)
            UserDefaults.standard.set(dictDevice, forKey: self.name)
            //UserDefaults.standard.synchronize()
        }
        
        print("plist data complete")

    }

    func throttle(){
        DispatchQueue.global(qos: .utility).async {
            if self.active && !self.unsupported {
                
                if self.userSpeed >= self.speedTable.count {
                    self.userSpeed = 0
                }
                
                let speed = self.speedTable[self.userSpeed]
                //print("setting speed to \(UInt16(speed))")
                
                Drive.setSpeed(UInt16(speed), forPath: self.path, withType: self.type)

                //print("speed is now: " + Drive.getSpeedForPath(self.path, withType: self.type).stringValue)
            }
        }
    }
    
}

