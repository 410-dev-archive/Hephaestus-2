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
    let version = "4.0 Open Beta 5"
    let bundlePath = Bundle.main.resourcePath ?? "~/Downloads/HephaestusLauncher2.app/Contents/Resources/Hephaestus 2.app/Contents/Resources"
    var requiredBootStraps = true
    let minimumOSCompatibility = 10.14
    let maximumOSCompatibility = 10.15
    var currentVersion = 0.0
    var cachingDir = ""
    
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
    var ignoreDiskSpace = false
    var installationTargetVersion = "10.15"
    
    override func viewDidLoad() {
        println("Hello from viewDidLoad().")
        println("Hephaestus 2 v." + version)
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
        cachingDir = System.readFile(pathway: "/usr/local/mpkglib/usersupport/localuser").replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "") + "/hephaestustmp"
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
                Arguments.isHidden = false
                Arguments.placeholderString = "Username"
                SecureTextField.placeholderString = "Password"
            }else if ETCCommands.stringValue.elementsEqual("Install Substitute OS") {
                Graphics.msgBox_Message(title: "Installing Substitute OS", contents: "Please enter the version you want to install.\nDeprecated version cannot be installed.\nPlease notice: Check wheter your Mac supports the OS.\nPlease notice: If your primary boot drive is NOT APFS, substitute installation will not work.\nAvailable versions: 10.14 / 10.15")
                SecureTextField.isHidden = true
                Arguments.isHidden = false
                Arguments.placeholderString = "OS Version (10.14 / 10.15)"
            }else if ETCCommands.stringValue.elementsEqual("Reinstall OS") {
                Graphics.msgBox_Message(title: "Reinstalling OS", contents: "Please enter the version you want to install.\nDeprecated version cannot be installed.\nPlease notice: Check wheter your Mac supports the OS.\nAvailable versions: 10.14 / 10.15")
                SecureTextField.isHidden = true
                Arguments.isHidden = false
                Arguments.placeholderString = "OS Version (10.14 / 10.15)"
            }else if ETCCommands.stringValue.elementsEqual("Full Clone (Backup)") {
                Graphics.msgBox_Message(title: "Making Full Clone", contents: "Please enter the external drive name. The drive will be completely erased, so MAKE SURE THERE IS NO IMORTANT DATA, EVEN IN A SEPARATED PARTITION.")
                SecureTextField.isHidden = true
                Arguments.isHidden = false
                Arguments.placeholderString = "Disk name"
            }else if ETCCommands.stringValue.elementsEqual("Fix broken application") {
                Graphics.msgBox_Message(title: "Fixing broken application", contents: "Please enter the application path. You can just drag and drop the app to the text field.")
                SecureTextField.isHidden = true
                Arguments.isHidden = false
                Arguments.placeholderString = "Application Path"
            }else if ETCCommands.stringValue.elementsEqual("Enable O-ROM Boot") {
                Graphics.msgBox_Message(title: "Enabling O-ROM Boot", contents: "O-ROM boot enabling requires unlocked firmware password. The tool will check whether the firmware lock is enabled or not, and if the firmware lock is enabled, the app may crash. If firmware lock is enabled, please turn it OFF. Firmware lock is turned off in default.")
                SecureTextField.isHidden = true
                Arguments.isHidden = true
                Arguments.placeholderString = "Arguments"
            }else{
                Arguments.placeholderString = "Arguments"
                SecureTextField.placeholderString = "Secure Text Field"
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
                Graphics.msgBox_Message(title: "Available Debug commands", contents: "debug.full-erase-kisutils\ndebug.erase-backup\ndebug.erase-libs\ndebug.noerase-backup-after-restore\ndebug.ignore-spacecheck")
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
            }else if command.elementsEqual("debug.ignore-spacecheck") {
                noShowRanTask = true
                Graphics.msgBox_Message(title: "Attention!", contents: "This option will disable checking disk space. This option will disable automatically once you've restarted the app.")
                ignoreDiskSpace = true
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
        }else if ETCCommands.stringValue.elementsEqual("Install Substitute OS") {
            if Arguments.stringValue.elementsEqual("10.14"){
                if currentVersion > 10.14{
                    println("deprecated version: 10.14")
                    if Graphics.msgBox_QMessage(title: "deprecated version", contents: "10.14 is not installable because it is deprecated version. Would you install the lowest version availabe? (" + String(currentVersion) + ")") {
                        installationTargetVersion = String(currentVersion)
                        installSubstituteOS(targetVersion: String(currentVersion))
                    }else{
                        noShowRanTask = true
                        println("Aborted.")
                        Graphics.msgBox_Message(title: "Aborted", contents: "Aborted installing substitute OS.")
                    }
                }else{
                    println("Will install: 10.14")
                    installationTargetVersion = "10.14"
                    installSubstituteOS(targetVersion: "10.14")
                }
            }else if Arguments.stringValue.elementsEqual("10.15") {
                println("Will install: 10.15")
                installationTargetVersion = "10.15"
                installSubstituteOS(targetVersion: "10.15")
            }else{
                updateStatus("Ready")
                currentStep = 0.0
                println("Unrecognized version identifier: " + Arguments.stringValue)
                Graphics.msgBox_errorMessage(title: "Version String Unrecognized", contents: "Version " + Arguments.stringValue + " is not recognizable version. Please type in either two: 10.14 or 10.15\nCodenames:\n10.14: Mojave\n10.15: Catalina")
            }
        }else if ETCCommands.stringValue.elementsEqual("Reinstall OS") {
            if Arguments.stringValue.elementsEqual("10.14"){
                if currentVersion > 10.14{
                    println("deprecated version: 10.14")
                    if Graphics.msgBox_QMessage(title: "Deprecated version", contents: "10.14 is not installable because it is deprecated version. Would you install the lowest version availabe? (" + String(currentVersion) + ")") {
                        installationTargetVersion = String(currentVersion)
                        installSubstituteOS(targetVersion: String(currentVersion))
                    }else{
                        noShowRanTask = true
                        println("Aborted.")
                        Graphics.msgBox_Message(title: "Aborted", contents: "Aborted installing substitute OS.")
                    }
                }else{
                    println("Will install: 10.14")
                    installationTargetVersion = "10.14"
                    installSubstituteOS(targetVersion: "10.14")
                }
            }else if Arguments.stringValue.elementsEqual("10.15") {
                println("Will install: 10.15")
                installationTargetVersion = "10.15"
                installSubstituteOS(targetVersion: "10.15")
            }else{
                updateStatus("Ready")
                currentStep = 0.0
                println("Unrecognized version identifier: " + Arguments.stringValue)
                Graphics.msgBox_errorMessage(title: "Version String Unrecognized", contents: "Version " + Arguments.stringValue + " is not recognizable version. Please type in either two: 10.14 or 10.15\nCodenames:\n10.14: Mojave\n10.15: Catalina")
            }
        }else if ETCCommands.stringValue.elementsEqual("Full Clone (Backup)") {
            if !Arguments.stringValue.elementsEqual("") {
                performFullBackup(toDrive: Arguments.stringValue)
            }else{
                println("Empty device name!")
                Graphics.msgBox_errorMessage(title: "Empty disk name", contents: "Please enter your backup disk name.")
            }
        }else if ETCCommands.stringValue.elementsEqual("Fix broken application") {
            System.sh("spctl", "--master-disable")
            ranTasks = ranTasks + "Unlocked GateKeeper\n"
            if !Arguments.stringValue.elementsEqual("") {
                System.sh("xattr", "-xc", Arguments.stringValue)
                ranTasks = ranTasks + "Ran XATTR\n"
            }else{
                println("No path.")
            }
        }else if ETCCommands.stringValue.elementsEqual("Enable O-ROM Boot") {
            println("Checking firmware lock...")
            updateStatus("Check FWL")
            System.sh(bin + "timeout", "4")
            System.sh(bundlePath + "/bootstraps/checkFwl", cachingDir)
            if System.readFile(pathway: cachingDir + "/fwlstatus").contains("No") {
                println("Enabling orom...")
                updateStatus("Modify NVRAM")
                System.sh(bin + "timeout", "1")
                updateStatus("Enabling OROM")
                System.sh("nvram", "enable-legacy-orom-behavior=1")
                ranTasks = ranTasks + "Enabled O-ROM with NVRAM\n"
            }else{
                Graphics.msgBox_errorMessage(title: "Locked", contents: "Firmware is locked with firware password. Remove it first to resume.")
                noShowRanTask = true
            }
        }else if ETCCommands.stringValue.elementsEqual("NextOptionWillBeHere") {
            
        }else{
            noShowRanTask = true
            Graphics.msgBox_errorMessage(title: "Error", contents: "No valid option available.")
        }
    }
    
    func getOS(targetVersion: String) -> Bool {
        var stop = false
        updateStatus("Set BIN")
        let bin = bundlePath + "/cmds-substituteoshelper/"
        updateStatus("Create Caching Drive")
        println("Caching drive: " + cachingDir)
        if !System.checkFile(pathway: cachingDir) {
            System.sh("mkdir", cachingDir)
            ranTasks = ranTasks + "\nCreated Caching Drive"
        }
        println("Setting helpers with chmod +x")
        System.sh("chmod", "+x", bin + "*")
        updateStatus("Getting Bootdrive Type")
        System.sh(bin + "getDiskType", cachingDir)
        ranTasks = ranTasks + "\nVerified Disk type"
        if !System.checkFile(pathway: cachingDir + "/isAPFS") {
            println("BOOT DRIVE IS NOT APFS!")
            Graphics.msgBox_errorMessage(title: "Non-APFS Bootdrive", contents: "It seems your root drive is not an APFS Volume (Failed verification). Please convert it first, then resume.")
            stop = true
        }else{
            println("Checking available disk space")
            updateStatus("Check disk space")
            System.sh(bin + "getDiskSpace", cachingDir)
            let rawData = System.readFile(pathway: cachingDir + "/availableDiskSpace")
            let availableVolume = Double(rawData.replacingOccurrences(of: " ", with: "").components(separatedBy: "Gi")[2])
            if availableVolume! <= 32 && !ignoreDiskSpace {
                println("Not enough disk space!")
                Graphics.msgBox_errorMessage(title: "Insufficient Disk Space", contents: "Your boot drive MUST have an empty space that is larger than 32GB. Please clear up your Time Machine Snapshots if you have any.")
                stop = true
            }else{
                updateStatus("Request for factory image")
                let imageHostServer = System.readFile(pathway: bundlePath + "/dynamicpreferences/hostserver").replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "\n", with: "")
                println("Check HOST online...")
                System.sh("chmod", "+x", bin + "downloadfactoryimageindex")
                System.sh(bin + "downloadfactoryimageindex", cachingDir, imageHostServer)
                println("Verifying index...")
                ranTasks = ranTasks + "\nVerified Index"
                if System.readFile(pathway: cachingDir + "/indexdata").contains(installationTargetVersion) {
                    println("Found available version from server index.")
                    println("Downloading image...")
                    updateStatus("Retrieving Factory Image")
                    if !System.checkFile(pathway: cachingDir + "/image.dmg") {
                        System.sh("chmod", "+x", bin + "downloadfactoryimage")
                        System.sh(bin + "downloadfactoryimage", cachingDir, imageHostServer + "macOS-" + installationTargetVersion + ".dmg")
                        ranTasks = ranTasks + "\nDownloaded Image"
                    }else{
                        println("Image already downloaded.")
                    }
                    println("Unpacking image...")
                    updateStatus("Unpack Image")
                    println("Generating Temp Data")
                    System.sh("mkdir", cachingDir + "/unpackedimage")
                    println("Mounting image")
                    System.sh("hdiutil", "attach", cachingDir + "/image.dmg")
                    var codeNameOfOS = ""
                    if installationTargetVersion.elementsEqual("10.15") {
                        codeNameOfOS = "Catalina"
                    }else if installationTargetVersion.elementsEqual("10.14"){
                        codeNameOfOS = "Mojave"
                    }
                    println("Copying Image to /Applications")
                    updateStatus("Moving to permastorage")
                    System.sh("cp", "-r", "/Volumes/macOS-" + targetVersion + "/Install macOS " + codeNameOfOS + ".app", "/Applications/")
                    println("Detaching image")
                    updateStatus("Detach Image")
                    System.sh("hdiutil", "detach", "/Volumes/macOS-" + targetVersion)
                    println("Clean up")
                    updateStatus("Clean up")
                    System.sh("rm", "-r", cachingDir)
                    ranTasks = ranTasks + "\nCleared Cache Directory"
                }else if System.readFile(pathway: cachingDir + "/indexdata").contains("Operation time out") {
                    Graphics.msgBox_errorMessage(title: "Server interaction failure", contents: "Unable to reach to server: " + imageHostServer + ". Please check your computer is online, or server is online.")
                    stop = true
                }else{
                    Graphics.msgBox_errorMessage(title: "Error", contents: "Server interaction failed.")
                    stop = true
                }
            }
        }
        return stop
    }
    
    func installSubstituteOS (targetVersion: String) {
        if !getOS(targetVersion: targetVersion) {
            let bin = bundlePath + "/cmds-substituteoshelper/"
            updateStatus("Create APFS volume")
            println("Create APFS volume")
            System.sh("chmod", "+x", bin + "makeapfsvolume")
            System.sh(bin + "makeapfsvolume", "Substitute")
            ranTasks = ranTasks + "\nCreated substitute volume"
            println("Executing installer command")
            updateStatus("Installer Command")
            var codeNameOfOS = ""
            if Arguments.stringValue.elementsEqual("10.15") {
                codeNameOfOS = "Catalina"
            }else if Arguments.stringValue.elementsEqual("10.14"){
                codeNameOfOS = "Mojave"
            }
            System.sh("/Applications/Install macOS " + codeNameOfOS + ".app/Contents/Resources/startosinstall", "--nointeraction", "--agreetolicense", "--applicationpath", "/Applications/Install macOS " + codeNameOfOS + ".app/Contents/Resources/startosinstall", "--volume", "/Volumes/Substitute")
            ranTasks = ranTasks + "Executed Installer Command\n"
        }else{
            Graphics.msgBox_criticalSystemErrorMessage(errorType: "Prepare Failed", errorCode: "<STOP>", errorClass: "ViewController.swift", errorLine: "multi", errorMethod: "getOS", errorMessage: "Prepare tool returned unprepared code.")
        }
    }
    
    func reinstallOS (targetVersion: String) {
        if !getOS(targetVersion: targetVersion) {
            println("Executing installer command")
            updateStatus("Installer Command")
            var codeNameOfOS = ""
            if Arguments.stringValue.elementsEqual("10.15") {
                codeNameOfOS = "Catalina"
            }else if Arguments.stringValue.elementsEqual("10.14"){
                codeNameOfOS = "Mojave"
            }
            let bin = bundlePath + "/cmds-substituteoshelper/"
            System.sh(bin + "getcurrentvolume", cachingDir)
            System.sh("/Applications/Install macOS " + codeNameOfOS + ".app/Contents/Resources/startosinstall", "--nointeraction", "--agreetolicense", "--applicationpath", "/Applications/Install macOS " + codeNameOfOS + ".app/Contents/Resources/startosinstall", "--volume", "/Volumes/" + System.readFile(pathway: cachingDir + "/thisVolumeName"))
            ranTasks = ranTasks + "Executed Installer Command\n"
        }else{
            Graphics.msgBox_criticalSystemErrorMessage(errorType: "Prepare Failed", errorCode: "<STOP>", errorClass: "ViewController.swift", errorLine: "multi", errorMethod: "getOS", errorMessage: "Prepare tool returned unprepared code.")
        }
    }
    
    func performFullBackup (toDrive: String) {
        if System.checkFile(pathway: toDrive) {
            if Graphics.msgBox_QMessage(title: "ERASE DISK", contents: "The target disk will be fully erased. The partition map will be re-written, therefore other partitions on the disk will be cleaned. Are you sure you have backed up your data in the disk, and continue?") {
                println("Grab disk identifier")
                updateStatus("Grabbing Device ID")
                let bin = bundlePath + "/cmds-generatebackup/"
                System.sh(bin + "grabDiskIdentifier", cachingDir, toDrive)
                let deviceID = System.readFile(pathway: cachingDir + "/deviceID")
                println("Checking disk size")
                updateStatus("Checking Disk Size")
                System.sh(bin + "getlocaldiskspace", cachingDir)
                System.sh(bin + "getdestdiskspace", cachingDir, toDrive)
                let SysVolSize = Double(System.readFile(pathway: cachingDir + "/localdiskspace").components(separatedBy: " ")[1].components(separatedBy: "Gi")[0].replacingOccurrences(of: " ", with: ""))
                let RmtVolSize = Double(System.readFile(pathway: cachingDir + "/targetdiskspace").components(separatedBy: " ")[1].components(separatedBy: "Gi")[0].replacingOccurrences(of: " ", with: ""))
                if SysVolSize! > RmtVolSize! && !ignoreDiskSpace {
                    println("Too small!!!")
                    Graphics.msgBox_errorMessage(title: "Target Disk Too Small", contents: "The target disk has to be larger or equal than the local disk size.")
                }else{
                    println("Erasing disk...")
                    updateStatus("Erase Disk")
                    System.sh(bin + "erasedisk", deviceID)
                    ranTasks = ranTasks + "Erased previous backup drive\n"
                    println("Starting Clone!!")
                    updateStatus("Clone")
                    System.sh(bin + "clone", System.readFile(pathway: bundlePath + "/dynamicpreferences/clone_exclude"))
                    ranTasks = ranTasks + "Cloned disk\n"
                    println("Making bootable")
                    updateStatus("Setting bootable")
                    System.sh("bless", "-folder", "/Volumes/BackupDrive/System/Library/CoreServices")
                    ranTasks = ranTasks + "Set clone bootable\n"
                    println("Done")
                    updateStatus("Done")
                }
            }else{
                noShowRanTask = true
                println("Aborted.")
                Graphics.msgBox_Message(title: "Aborted", contents: "Stopped performing backup.")
            }
        }else{
            println("Not found.")
            Graphics.msgBox_errorMessage(title: "Disk does not exists", contents: "The selected backup disk does not exists.")
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
        Status.stringValue = "Done"
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

