//
//  ContainerViewController.swift
//  DiscRotate
//
//  Created by georg on 11.10.17.
//  Copyright © 2017 Georg Wacker. All rights reserved.
//

import Cocoa

@objcMembers
class ViewController: NSViewController {
    
    static let shared = ViewController.instance()

    @IBOutlet weak var versionInfo: NSTextField!
    @IBOutlet var optionsMenu: NSMenu!
    @IBOutlet var emptyCell: NSView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var tableView: NSTableView!
    
    let appd = NSApplication.shared.delegate as! AppDelegate
    let dummy = MediaDevice(name: "<empty>", path: "", type: "")
    var devices = [MediaDevice]()

    @IBAction func openMenu(_ sender: NSButton) {
        optionsMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: sender.frame.origin.y + sender.frame.height), in: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.translatesAutoresizingMaskIntoConstraints = true
        
        let dict = Bundle.main.infoDictionary!
        let name = dict["CFBundleName"] as! String
        let version = dict["CFBundleShortVersionString"] as! String
        //let build = dict["CFBundleVersion"] as! String
        versionInfo.stringValue = "\(name) v\(version)"
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // set the device to unsupported, to avoid being included in the throttle loop
        dummy.unsupported = true
        
        // add dummy device to the table view, to start with an empty state, as the initial speed test could take x seconds
        devices.append(dummy)
        
        tableView.reloadData()
        resizeView()
    }
    
    @IBAction func quit(_ sender: NSMenuItem) {
        NSApp.terminate(self)
        // TODO: reset speed on devices to full when exiting?
    }
    
    func addDevice(_ device: MediaDevice){
        //making sure the view is loaded and setup
        let _ = self.view
        
        if let i = devices.index(where: { $0.name == "<empty>"}) {
            devices.remove(at: i)
        }
        devices.append(device)
        tableView?.reloadData()
        resizeView()
    }
    
    func removeDevice(_ deviceName: String){
        //making sure the view is loaded and setup
        let _ = self.view
        
        if let i = devices.index(where: { $0.name == deviceName }) {
            let _ = devices.remove(at: i)
        }
        if devices.count == 0 {
            devices.append(dummy)
        }
        tableView?.reloadData()
        resizeView()
    }
    
    func resizeView() {
        let size = NSSize(width: Int(view.frame.width), height: 100 * devices.count + 40)
        view.setFrameSize(size)
        appd.popover.contentSize = size
    }
}

extension ViewController {
    static func instance() -> ViewController{
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let id = NSStoryboard.SceneIdentifier("ViewController")
        return storyboard.instantiateController(withIdentifier: id) as! ViewController
    }
}

extension ViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return devices.count
    }
}

extension ViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let dev = devices[row]
        
        if dev.name == "<empty>" {
           return emptyCell
        }

        let main = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let dvc = main.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "DeviceViewControllerID")) as! DeviceViewController
        dvc.representedObject = dev
        return dvc.view
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return CGFloat(98)
    }
    
    func tableView(_ tableView: NSTableView, didAdd rowView: NSTableRowView, forRow row: Int) {
        resizeView()
    }
    
    func tableView(_ tableView: NSTableView, didRemove rowView: NSTableRowView, forRow row: Int) {
        resizeView()
    }

}
