//
//  ViewController.swift
//  Hephaestus 2
//
//  Created by Hoyoun Song on 2019/08/26.
//  Copyright © 2019 Hoyoun Song. All rights reserved.
//

import Cocoa
import Network

class ViewController: NSViewController {
    @IBOutlet weak var ProgressBar: NSProgressIndicator!
    @IBOutlet weak var Spinner: NSProgressIndicator!
    @IBOutlet weak var Progress: NSTextField!
    @IBOutlet weak var Status: NSTextField!
    @IBOutlet weak var TargetTask: NSSegmentedControl!
    @IBOutlet weak var VersionString: NSTextField!
    @IBOutlet weak var Outlet_Button: NSButton!
    @IBOutlet weak var Outlet_Quit: NSButton!
    
    let System: SystemLevelCompatibilityLayer = SystemLevelCompatibilityLayer()
    let Graphics: GraphicComponents = GraphicComponents()
    let MaxStep = 16.0
    var currentStep = 0.0
    let MaxStepInString = "16"
    let version = "Release Candidate 4"
    let bundlePath = Bundle.main.resourcePath ?? "~/Downloads/HephaestusLauncher2.app/Contents/Resources/Hephaestus 2.app/Contents/Resources"
    var requiredBootStraps = true
    let minimumOSCompatibility = 10.14
    let maximumOSCompatibility = 10.15
    var currentVersion = 0.0
    
    let bin = "/usr/local/Libertas/Library/scripts/"
    let backupPath = "/usr/local/Libertas/Library/distribution/Hephaestus2/backup"
    let Library = "/usr/local/Libertas/Library/"
    var noRunRecord = false
    var networkConnected = false
    
    override func viewDidLoad() {
        println("Hello from viewDidLoad().")
        println("Loading OS information...")
        let os = ProcessInfo().operatingSystemVersion
        println("Version detected: " + String(os.majorVersion) + "." + String(os.minorVersion))
        switch (os.majorVersion, os.minorVersion, os.patchVersion) {
        case (10, 14, _):
            currentVersion = 10.14
        case (10, 15, _):
            currentVersion = 10.15
            Graphics.msgBox_Message(title: "Unconfirmed Environment", contents: "macOS 10.15 is not a tested environment. Please let the developer to know if there is a bug.")
        default:
            println("Version detected: " + String(os.majorVersion) + "." + String(os.minorVersion))
            currentVersion = 0
        }
        if currentVersion < minimumOSCompatibility || currentVersion > maximumOSCompatibility{
            println("Incompatible OS version.")
            Graphics.msgBox_errorMessage(title: "Incompatible", contents: "The OS version is incompatible with Hephaestus 2.")
            exit(1)
        }
        println("Setting script permission...")
        System.sh("chmod", "+x", bundlePath + "/bootstraps/installbootstraps")
        println("Checking status...")
        if System.checkFile(pathway: Library + "COM/flags/jailbroken.stat") {
            println("Jailbroken.")
            TargetTask.setEnabled(false, forSegment: 0)
            TargetTask.setSelected(true, forSegment: 1)
        }else if System.checkFile(pathway: Library + "COM/flags/restored.stat") {
            println("Restored.")
            TargetTask.setEnabled(false, forSegment: 1)
            TargetTask.setSelected(true, forSegment: 0)
        }else{
            println("First launch.")
            noRunRecord = true
            TargetTask.setEnabled(false, forSegment: 1)
            TargetTask.setSelected(true, forSegment: 0)
        }
        if !String(System.getUsername() ?? "nil").elementsEqual("root") {
            println("Permission is NOT root!")
            Graphics.msgBox_errorMessage(title: "Permission Denied", contents: "It seems Hephaestus launched incorrectly. Please use official launcher to launch.")
            exit(-9)
        }
        println("Maximum process string update...")
        Progress.stringValue = "0/" + MaxStepInString
        println("Ready.")
        super.viewDidLoad()
        if System.checkFile(pathway: "/Library/ff") {
           Graphics.msgBox_Message(title: "View Loaded", contents: "View is loaded.")
        }
    }
    
    func println(_ msg: String) {
        print("[Hephaestus2] " + msg)
    }
    
    @IBAction func Action_Button(_ sender: Any) {
        println("Set maximum value: " + MaxStepInString)
        ProgressBar.maxValue = MaxStep
        println("Initialize begin value: 0.0")
        ProgressBar.doubleValue = 0.0
        Outlet_Button.title = "Running"
        updateStatus("Check System")
        Outlet_Quit.isEnabled = false
        Outlet_Button.isEnabled = false
        var targetTaskIsJailbreak = true
        if TargetTask.selectedSegment == 0 {
            targetTaskIsJailbreak = true
        }else{
            targetTaskIsJailbreak = false
        }
        TargetTask.isEnabled = false
        Spinner.startAnimation("")
        if System.checkFile(pathway: "/usr/local/mpkglib/db/libhephaestus-libertas") {
            println("Incompatible Hephaestus Library installed.")
            Graphics.msgBox_errorMessage(title: "Deprecated Hephaestus Installed", contents: "Hephaestus 1 seems installed. It is not compatible with Hephaestus 2, and may screw up the whole system. Please restore LanSchool using Hephaestus 1, then fully remove Hephaestus 1 with its launcher. Then launch this app. The app will now exit.")
            exit(-9)
        }
        if targetTaskIsJailbreak {
            actionJailbreak()
        }else{
            actionRestore()
        }
        Spinner.stopAnimation("")
        Outlet_Button.title = "Done"
        if Graphics.msgBox_QMessage(title: "Reboot Now?", contents: "To take effect, you need to reboot now. Would you reboot?") {
            System.sh("reboot")
        }else{
            TargetTask.isEnabled = true
            Outlet_Quit.isEnabled = true
            Outlet_Button.isEnabled = true
            exit(0)
        }
    }
    
    func actionJailbreak() {
        updateStatus("Install package manager")
        System.sh(bundlePath + "/bootstraps/installbootstraps", "mpkg")
        updateStatus("Install support libraries")
        System.sh(bundlePath + "/bootstraps/installbootstraps", "libusersupport")
        System.sh(bundlePath + "/bootstraps/installbootstraps", "libertas-" + String(currentVersion))
        updateStatus("Build Sector Library")
        if !System.checkFile(pathway: backupPath) {
            System.sh("mkdir", Library + "distribution/Hephaestus2")
            System.sh("mkdir", backupPath)
        }
        updateStatus("Verify Install")
        if !System.checkFile(pathway: Library) {
            Graphics.msgBox_errorMessage(title: "Libertas Libraries not installed", contents: "Failed installing Libertas-Core libraries. Hephaestus will not work unless Libertas is installed correctly.")
            exit(-9)
        }else{
            System.sh(bin + "timeout", "2")
        }
        updateStatus("Create Backup")
        if !System.checkFile(pathway: backupPath + "/Library/Application Support/LanSchool") {
            System.sh(bin + "backup", "make", backupPath)
        }
        updateStatus("Kill Task")
        System.sh(bin + "killtask", "-9")
        updateStatus("Create Fake Task Port")
        if currentVersion != 10.14 {
            System.sh(bin + "faketaskport")
        }else{
            System.sh(bin + "timeout", "3")
        }
        updateStatus("Core Patch")
        System.sh(bin + "corepatch", "do")
        updateStatus("Open Port")
        if currentVersion != 10.14 {
            System.sh(bin + "openport")
        }else{
            System.sh(bin + "rest", "1")
        }
        updateStatus("DSCL Patch")
        System.sh(bin + "dsclpatch", "do")
        updateStatus("Set Port")
        if currentVersion != 10.14 {
            System.sh(bin + "setport", "do")
        }else{
            System.sh(bin + "timeout", "2")
        }
        updateStatus("Launchctl Patch")
        System.sh(bin + "launchctlmgr", "unload")
        updateStatus("Kill Task")
        System.sh(bin + "killtask")
        if !System.checkFile(pathway: "/Library/Application Support/LanSchool") {
            updateStatus("Update Status")
            System.sh(bin + "writeflag", "success")
            updateStatus("Clean Up")
            System.sh(bin + "timeout", "3")
        }else{
            Graphics.msgBox_criticalSystemErrorMessage(errorType: "fail", errorCode: "2", errorClass: "ViewController.swift", errorLine: "if System.checkFile(pathway: \"/Library/Application Support/LanSchool\") {", errorMethod: "func actionJailbreak() {", errorMessage: "Failed removing LanSchool library.")
            exit(-9)
        }
    }
    
    func actionRestore() {
        updateStatus("Restore Backup")
        System.sh(bin + "backup", "restore", backupPath)
        updateStatus("DSCL Patch")
        System.sh(bin + "dsclpatch", "restore")
        updateStatus("Launchctl Patch")
        System.sh(bin + "launchctlmgr", "load")
        updateStatus("Update Status")
        System.sh(bin + "writeflag", "restored")
        updateStatus("Delete Backup")
        System.sh(bin + "backup", "delete", backupPath)
        updateStatus("Uninstall Supporting libraries")
        if currentVersion == 10.14 {
            System.sh("/usr/local/bin/mpkg", "-r", "jailbreakd-libertas")
        }else{
            System.sh("/usr/local/bin/mpkg", "-r", "jailbreakd-libertas-10.15.x")
        }
        System.sh("/usr/local/bin/mpkg", "-r", "libusersupport")
        updateStatus("Clean Up")
        ProgressBar.doubleValue = MaxStep
        Progress.stringValue = MaxStepInString + "/" + MaxStepInString
    }
    
    @IBAction func Action_Quit(_ sender: Any) {
        if Graphics.msgBox_QMessage(title: "Would you quit?", contents: "You are about to quit. Continue?") {
            exit(0)
        }
    }
    
    func updateStatus(_ message: String) {
        currentStep = currentStep + 1
        ProgressBar.doubleValue = currentStep
        Progress.stringValue = String(Int(currentStep)) + "/" + MaxStepInString
        Status.stringValue = message
        println("Status update: " + String(Int(currentStep)) + "/" + MaxStepInString + " " + message)
    }
    
    override var representedObject: Any? {
        didSet {
            
        }
    }


}

