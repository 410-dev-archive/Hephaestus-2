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
    @IBOutlet weak var ETCCommands: NSComboBox!
    @IBOutlet weak var Arguments: NSTextField!
    @IBOutlet weak var SecureTextField: NSSecureTextField!
    
    let System: SystemLevelCompatibilityLayer = SystemLevelCompatibilityLayer()
    let Graphics: GraphicComponents = GraphicComponents()
    let MaxStep = 19.0
    var currentStep = 0.0
    let MaxStepInString = "19"
    let version = "2.0 Public Release"
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
    var hiddenUserCtrlEnabled = true
    var prevExtOption = 99999999
    var ranTasks = ""
    var noShowRanTask = false
    var skipBackup = false
    var dontEraseBackupAfterRestore = false
    
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
            if !System.checkFile(pathway: "/Library/Application Support/LanSchool/student") {
                println("Non-KIS image.")
                TargetTask.setEnabled(false, forSegment: 0)
                TargetTask.setSelected(true, forSegment: 2)
                Graphics.msgBox_Message(title: "Non-KIS Image", contents: "This system is not fully supported for Hephaestus Liberation. Only extra features will be enabled.")
                ETCCommands.isHidden = false
                Arguments.isHidden = false
                if System.checkFile(pathway: "/usr/local/libhiddenuser/created.stat") {
                    ETCCommands.removeItem(at: 0)
                }else{
                    ETCCommands.removeItem(at: 2)
                    ETCCommands.removeItem(at: 1)
                }
            }
        }
        if !String(System.getUsername() ?? "nil").elementsEqual("root") && !System.checkFile(pathway: "/Library/ff") {
            println("Permission is NOT root!")
            Graphics.msgBox_errorMessage(title: "Permission Denied", contents: "It seems Hephaestus launched incorrectly. Please use official launcher to launch.")
            exit(-9)
        }
        println("Maximum process string update...")
        Progress.stringValue = "0/" + MaxStepInString
        println("Sets.")
        ETCCommands.isHidden = true
        Arguments.isHidden = true
        SecureTextField.isHidden = true
        VersionString.stringValue = version
        println("Ready.")
        Graphics.msgBox_Message(title: "Click Icon", contents: "Click Hephaestus 2 icon from the dock to show the window.")
        super.viewDidLoad()
        super.viewWillAppear()
        super.viewDidAppear()
    }
    
    func println(_ msg: String) {
        print("[Hephaestus2] " + msg)
    }
    
    @IBAction func SelectOption(_ sender: Any) {
        if TargetTask.selectedSegment == 2 {
            ETCCommands.isHidden = false
            Arguments.isHidden = false
        }else{
            ETCCommands.isHidden = true
            Arguments.isHidden = true
            SecureTextField.isHidden = true
        }
    }
    
    @IBAction func SelectedExtraAction(_ sender: Any) {
        println("Selected: " + String(ETCCommands.indexOfSelectedItem))
        if prevExtOption != ETCCommands.indexOfSelectedItem {
            if ETCCommands.stringValue.elementsEqual("Create Hidden User") {
                Graphics.msgBox_Message(title: "Warning for Creating a Hidden User", contents: "Please notice that the username should NOT include space, and will be used for login.")
                SecureTextField.isHidden = false
            }else{
                SecureTextField.isHidden = true
            }
        }
        prevExtOption = ETCCommands.indexOfSelectedItem
    }
    
    func installBootStrap() {
        if !System.checkFile(pathway: "/usr/local/mpkglib/db/libusersupport") {
            updateStatus("Install package manager")
            System.sh(bundlePath + "/bootstraps/installbootstraps", "mpkg")
            ranTasks = ranTasks + "\nInstalled pkgmgr"
            updateStatus("Install support libraries")
            System.sh(bundlePath + "/bootstraps/installbootstraps", "libusersupport")
            ranTasks = ranTasks + "\nInstalled libusersupport"
            System.sh(bundlePath + "/bootstraps/installbootstraps", "libertas-" + String(currentVersion))
            ranTasks = ranTasks + "\nInstalled liblibertas"
            updateStatus("Build Sector Library")
            if !System.checkFile(pathway: backupPath) {
                System.sh("mkdir", Library + "distribution/Hephaestus2")
                System.sh("mkdir", backupPath)
                ranTasks = ranTasks + "\nBuilt sector library"
            }
            updateStatus("Verify Install")
            if !System.checkFile(pathway: Library) {
                Graphics.msgBox_errorMessage(title: "Libertas Libraries not installed", contents: "Failed installing Libertas-Core libraries. Hephaestus will not work unless Libertas is installed correctly.")
                exit(-9)
            }else{
                System.sh(bin + "timeout", "2")
            }
        }else{
            updateStatus("Installed package manager")
            updateStatus("Installed support libraries")
            updateStatus("Build Sector Library")
            updateStatus("Verify Install")
        }
    }
    
    func actionExtra() {
        var created = false
        if System.checkFile(pathway: "/usr/local/libhiddenuser/created.stat") {
            created = true
        }else{
            created = false
            if !System.checkFile(pathway: "/usr/local/libhiddenuser") {
                System.sh("mkdir", "/usr/local/libhiddenuser")
                ranTasks = ranTasks + "\nCreated lhidflag storage"
            }
        }
        if ETCCommands.stringValue.elementsEqual("Create Hidden User"){
            if !created {
                println("Reading arguments...")
                println("Username: " + Arguments.stringValue.replacingOccurrences(of: " ", with: "_"))
                println("Password: " + SecureTextField.stringValue)
                if Arguments.stringValue.elementsEqual("") || SecureTextField.stringValue.elementsEqual("") {
                    Graphics.msgBox_errorMessage(title: "Empty Fields", contents: "Some fields are empty. Please fill them.")
                    updateStatus("Ready")
                    currentStep = 0.0
                }else if Arguments.stringValue.elementsEqual("kisadmin") || Arguments.stringValue.elementsEqual("ninjaadmin") {
                    Graphics.msgBox_errorMessage(title: "Reserved Usernames", contents: "These user names are reserved, and cannot be used as hidden account's name.")
                    updateStatus("Ready")
                    currentStep = 0.0
                }else{
                    actionCreateHiddenuser()
                }
            }else{
                Graphics.msgBox_errorMessage(title: "Existing Hidden User", contents: "Hidden user already exists. Please remove it first to create a new one.")
                updateStatus("Ready")
                currentStep = 0.0
            }
        }else if ETCCommands.stringValue.elementsEqual("Delete Hidden User") {
            if created{
                println("Reading arguments...")
                println("Username: " + Arguments.stringValue.replacingOccurrences(of: " ", with: "_"))
                if Arguments.stringValue.elementsEqual(""){
                    Graphics.msgBox_errorMessage(title: "Empty Field", contents: "Username field is empty. Please fill it.")
                    updateStatus("Ready")
                    currentStep = 0.0
                }else{
                    actionDeleteHiddenUser()
                }
            }else{
                Graphics.msgBox_errorMessage(title: "No Hidden User", contents: "Hidden user does not exists. Please make it first to delete.")
                updateStatus("Ready")
                currentStep = 0.0
            }
        }else if ETCCommands.stringValue.elementsEqual("Backup Hidden User") {
            if created {
                println("Reading arguments...")
                println("Username: " + Arguments.stringValue.replacingOccurrences(of: " ", with: "_"))
                if Arguments.stringValue.elementsEqual(""){
                    Graphics.msgBox_errorMessage(title: "Empty Field", contents: "Username field is empty. Please fill it.")
                    updateStatus("Ready")
                    currentStep = 0.0
                }else{
                    actionBackupHiddenUser()
                }
            }else{
                Graphics.msgBox_errorMessage(title: "No Hidden User", contents: "Hidden user does not exists. Please make it first to delete.")
                updateStatus("Ready")
                currentStep = 0.0
            }
        }else if ETCCommands.stringValue.starts(with: "debug.") {
            let command = ETCCommands.stringValue
            if ETCCommands.stringValue.elementsEqual("debug.help") {
                noShowRanTask = true
                Graphics.msgBox_Message(title: "Available Debug commands", contents: "debug.full-erase-kisutils\ndebug.erase-backup\ndebug.erase-libs\ndebug.noerase-backup-after-restore")
            }else if command.elementsEqual("debug.full-erase-kisutils") {
                skipBackup = true
                Graphics.msgBox_Message(title: "Attention!", contents: "Backup will be skipped when liberation. This will disable restoration too, which will permanently erase LanSchool from your Mac. To disable skip, relaunch Hephaestus.")
                noShowRanTask = true
            }else if command.elementsEqual("debug.erase-libs") {
                if Graphics.msgBox_QMessage(title: "Attention!", contents: "You are about to erase Hephaestus Support Libraries. This might destroy your backups. Would you continue?") {
                    updateStatus("Erase libertas")
                    if currentVersion == 10.14 {
                        System.sh("/usr/local/bin/mpkg", "-r", "jailbreakd-libertas")
                    }else if currentVersion == 10.15 {
                        System.sh("/usr/local/bin/mpkg", "-r", "jailbreakd-libertas-10.15.x")
                    }
                    ranTasks = ranTasks + "\nErased libertas"
                    updateStatus("Erase libusersupport")
                    System.sh("/usr/local/bin/mpkg", "-r", "libusersupport")
                    ranTasks = ranTasks + "\nErased libusersupport"
                    if Graphics.msgBox_QMessage(title: "Erase Package Manager?", contents: "Would you uninstall the mpkg: package manager?\nWARNING: IF YOU HAVE INSTALLED OTHER PACKAGES THROUGH MPKG, DO NOT ERASE.") {
                        updateStatus("Erase mpkg")
                        System.sh("rm", "-r", "/usr/local/mpkglib")
                        System.sh("rm", "-r", "/etc/paths.d/mpkg")
                        ranTasks = ranTasks + "\nErased mpkg"
                    }
                    updateStatus("Done")
                }else{
                    noShowRanTask = true
                    Graphics.msgBox_Message(title: "Aborted", contents: "Stopped erasing task.")
                }
            }else if command.elementsEqual("debug.noerase-backup-after-restore") {
                noShowRanTask = true
                Graphics.msgBox_Message(title: "Attention!", contents: "Backup will not be removed after restore. This option will disable automatically once you've restarted the app.")
                dontEraseBackupAfterRestore = true
            }else if command.elementsEqual("debug.erase-backup") {
                if Graphics.msgBox_QMessage(title: "Erase Package Manager?", contents: "Would you uninstall the mpkg: package manager?\nWARNING: IF YOU HAVE INSTALLED OTHER PACKAGES THROUGH MPKG, DO NOT ERASE.") {
                    updateStatus("Erasing backup")
                    System.sh("rm", "-r", backupPath)
                    updateStatus("Done")
                    ranTasks = ranTasks + "\nErased backup"
                }else{
                    noShowRanTask = true
                    Graphics.msgBox_Message(title: "Aborted", contents: "Aborted erasing backup.")
                }
            }else{
                noShowRanTask = true
                Graphics.msgBox_errorMessage(title: "Error", contents: "No such debug command.")
            }
        }else{
            noShowRanTask = true
            Graphics.msgBox_errorMessage(title: "Error", contents: "No valid option available.")
        }
    }
    
    
    func actionCreateHiddenuser () {
        updateStatus("Set BIN")
        let bin = bundlePath + "/bootstraps/verstect/verstect_makehidden"
        let username = Arguments.stringValue.replacingOccurrences(of: " ", with: "_")
        updateStatus("Creating Default User")
        System.sh(bin, "createdefault", username)
        ranTasks = ranTasks + "\nCreated user: " + username
        updateStatus("Setting Shell")
        if currentVersion == 10.14 {
            System.sh(bin, "setsh", username, "/bin/bash")
            ranTasks = ranTasks + "\nSet shell to bash"
        }else{
            System.sh(bin, "setsh", username, "/bin/zsh")
            ranTasks = ranTasks + "\nSet shell to zsh"
        }
        updateStatus("Setting Name")
        System.sh(bin, "setname", username)
        ranTasks = ranTasks + "\nSet name"
        updateStatus("Force-Set UniqueID to 1001")
        System.sh(bin, "setuid", username, "1001")
        ranTasks = ranTasks + "\nSet UserID to 1001"
        updateStatus("Set PrimaryGroupID to 1000")
        System.sh(bin, "setprimarygroupid", username, "1000")
        ranTasks = ranTasks + "\nSet PrimaryGroupID to 1000"
        updateStatus("Initialize NFSHomeDirectory")
        System.sh(bin, "initnfshome", username)
        ranTasks = ranTasks + "\nInitialized NFSHomeDirectory"
        updateStatus("Add Password Lock")
        System.sh(bin, "setpw", username, SecureTextField.stringValue)
        ranTasks = ranTasks + "\nAdded Password Lock"
        updateStatus("Grant Admin Privilage")
        System.sh(bin, "grantmembership", username)
        ranTasks = ranTasks + "\nSet permission to administrator"
        updateStatus("Transfer")
        ranTasks = ranTasks + "\nTransfered initial library"
        updateStatus("Set NFSHomeDirectory")
        System.sh(bin, "setnfshome", username)
        ranTasks = ranTasks + "\nSet NFSHomeDirectory"
        updateStatus("Set Property: IsHidden=1")
        System.sh(bin, "hide", username)
        ranTasks = ranTasks + "\nSet as hidden user"
        updateStatus("Create Flag")
        System.sh("touch", "/usr/local/libhiddenuser/created.stat")
        ranTasks = ranTasks + "\nWrote safe flag"
        updateStatus("Done")
    }
    
    func actionDeleteHiddenUser () {
        let bin = bundlePath + "/bootstraps/verstect/verstect_removehidden"
        let username = Arguments.stringValue.replacingOccurrences(of: " ", with: "_")
        updateStatus("Query")
        updateStatus("Restore to IsHidden=0")
        System.sh(bin, "unhide", username)
        ranTasks = ranTasks + "\nUnhidden user"
        updateStatus("Roll-back")
        System.sh(bin, "rollback", username)
        ranTasks = ranTasks + "\nRestored user directory"
        updateStatus("Delete")
        System.sh(bin, "del", username)
        ranTasks = ranTasks + "\nDeleted user directory"
        updateStatus("Create Flag")
        System.sh("rm", "/usr/local/libhiddenuser/created.stat")
        ranTasks = ranTasks + "\nWrote safe flag"
        updateStatus("Done")
    }
    
    func actionBackupHiddenUser () {
        let bin = bundlePath + "/bootstraps/verstect/verstect_backuphidden"
        let username = Arguments.stringValue.replacingOccurrences(of: " ", with: "_")
        updateStatus("Create Temporary Storage")
        System.sh(bin, "gentemp")
        ranTasks = ranTasks + "\nCreated storage"
        updateStatus("Clone User")
        System.sh(bin, "clone", username)
        ranTasks = ranTasks + "\nCloned user"
        updateStatus("Update Ownership")
        let userdPath = System.readFile(pathway: "/usr/local/mpkglib/usersupport/localuser").split(separator: "/").map(String.init)
        let owner = userdPath.last!
        System.sh(bin, "ownership", username, owner)
        ranTasks = ranTasks + "\nChanged ownership"
        updateStatus("Compress")
        System.sh(bin, "compress", username)
        ranTasks = ranTasks + "\nCompressed to ZIP"
        updateStatus("Transfer")
        System.sh(bin, "transfer", username)
        ranTasks = ranTasks + "\nTransfered to current user directory"
        updateStatus("Cleanup")
        System.sh(bin, "cleanup", username)
        ranTasks = ranTasks + "\nCleaned up storage"
        updateStatus("Done")
    }
    
    
    @IBAction func Action_Button(_ sender: Any) {
        println("Set maximum value: " + MaxStepInString)
        ProgressBar.maxValue = MaxStep
        println("Initialize")
        noShowRanTask = false
        ranTasks = ""
        ProgressBar.minValue = 0.0
        ProgressBar.doubleValue = 0.0
        Progress.stringValue = "0/" + MaxStepInString
        Outlet_Button.title = "Running"
        updateStatus("Check System")
        Outlet_Quit.isEnabled = false
        Outlet_Button.isEnabled = false
        TargetTask.isEnabled = false
        Spinner.startAnimation("")
        if System.checkFile(pathway: "/usr/local/mpkglib/db/libhephaestus-libertas") {
            println("Incompatible Hephaestus Library installed.")
            Graphics.msgBox_errorMessage(title: "Deprecated Hephaestus Installed", contents: "Hephaestus 1 seems installed. It is not compatible with Hephaestus 2, and may screw up the whole system. Please restore LanSchool using Hephaestus 1, then fully remove Hephaestus 1 with its launcher. Then launch this app. The app will now exit.")
            exit(-9)
        }
        installBootStrap()
        println("Getting selected option...")
        if TargetTask.selectedSegment == 0 {
            println("Task: Jailbreak")
            actionJailbreak()
        }else if TargetTask.selectedSegment == 1 {
            println("Task: Restore")
            actionRestore()
            rebootToTakeEffect()
        }else if TargetTask.selectedSegment == 2 {
            println("Task: Extra")
            actionExtra()
        }
        Spinner.stopAnimation("")
        Outlet_Button.title = "Done"
        if !noShowRanTask {
            Graphics.msgBox_Message(title: "Process Complete", contents: "The process is complete.\nLaunched Tasks:\n\n" + ranTasks)
        }
        Outlet_Button.isEnabled = true
        Outlet_Quit.isEnabled = true
        TargetTask.isEnabled = true
        ProgressBar.minValue = 0.0
        ProgressBar.doubleValue = 0.0
        currentStep = 0.0
        Progress.stringValue = "0/" + MaxStepInString
    }
    
    func rebootToTakeEffect() {
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
        if System.checkFile(pathway: Library + "COM/flags/jailbroken.stat") {
            println("Jailbroken.")
            TargetTask.setEnabled(false, forSegment: 0)
            TargetTask.setSelected(true, forSegment: 1)
            Graphics.msgBox_Message(title: "Already Protected", contents: "Cannot run the process becuase LanSchool in your Mac is disabled.")
        }else if System.checkFile(pathway: Library + "COM/flags/restored.stat") {
            println("Restored.")
            TargetTask.setEnabled(false, forSegment: 1)
            TargetTask.setSelected(true, forSegment: 0)
            breakLS()
        }else{
            breakLS()
        }
    }
    
    func breakLS(){
        updateStatus("Create Backup")
        if !System.checkFile(pathway: backupPath + "/Library/Application Support/LanSchool") || skipBackup {
            ranTasks = ranTasks + "\nCreated LanSchool backup"
            System.sh(bin + "backup", "make", backupPath)
        }else{
            ranTasks = ranTasks + "\nSkipped backup"
        }
        updateStatus("Prepare for LaAC Protocol")
        updateStatus("Create Fake Task Port")
        if currentVersion != 10.14 {
            System.sh(bin + "faketaskport")
        }else{
            System.sh(bin + "timeout", "3")
        }
        updateStatus("Core Patch")
        System.sh(bin + "corepatch", "do")
        ranTasks = ranTasks + "\nCore Patched"
        updateStatus("Open Port")
        if currentVersion != 10.14 {
            System.sh(bin + "openport")
        }else{
            System.sh(bin + "rest", "1")
        }
        updateStatus("DSCL Patch")
        System.sh(bin + "dsclpatch", "do")
        ranTasks = ranTasks + "\nDSCL Patched"
        updateStatus("Set Port")
        if currentVersion != 10.14 {
            System.sh(bin + "setport", "do")
        }else{
            System.sh(bin + "timeout", "2")
        }
        updateStatus("Launchctl Patch")
        System.sh(bin + "launchctlmgr", "unload")
        ranTasks = ranTasks + "\nDisabled Auto-start LanSchool"
        updateStatus("Kill Task")
        ranTasks = ranTasks + "\nKilled p-LanSchool"
        ranTasks = ranTasks + "\nKilled p-student"
        System.sh(bin + "killtask", "-9")
        if !System.checkFile(pathway: "/Library/Application Support/LanSchool") {
            updateStatus("Update Status")
            System.sh(bin + "writeflag", "success")
            ranTasks = ranTasks + "\nWrote safe flag"
            updateStatus("Clean Up")
            System.sh(bin + "timeout", "3")
            ranTasks = ranTasks + "\nCleaned up"
        }else{
            Graphics.msgBox_criticalSystemErrorMessage(errorType: "fail", errorCode: "2", errorClass: "ViewController.swift", errorLine: "if System.checkFile(pathway: \"/Library/Application Support/LanSchool\") {", errorMethod: "func actionJailbreak() {", errorMessage: "Failed removing LanSchool library.")
            exit(-9)
        }
    }
    
    func actionRestore() {
        updateStatus("Restore Backup")
        System.sh(bin + "backup", "restore", backupPath)
        ranTasks = ranTasks + "\nRestored backup"
        updateStatus("DSCL Patch")
        System.sh(bin + "dsclpatch", "restore")
        ranTasks = ranTasks + "\nRestored DSCL"
        updateStatus("Launchctl Patch")
        System.sh(bin + "launchctlmgr", "load")
        ranTasks = ranTasks + "\nEnabled Auto-restart"
        updateStatus("Update Status")
        System.sh(bin + "writeflag", "restored")
        ranTasks = ranTasks + "\nWrote safe flag"
        updateStatus("Delete Backup")
        if !dontEraseBackupAfterRestore {
            System.sh(bin + "backup", "delete", backupPath)
            ranTasks = ranTasks + "\nDeleted backup"
        }
        updateStatus("Uninstall Supporting libraries")
        if currentVersion == 10.14 {
            System.sh("/usr/local/bin/mpkg", "-r", "jailbreakd-libertas")
        }else{
            System.sh("/usr/local/bin/mpkg", "-r", "jailbreakd-libertas-10.15.x")
        }
        System.sh("/usr/local/bin/mpkg", "-r", "libusersupport")
        ranTasks = ranTasks + "\nUninstalled supporting libraries"
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

