//
//  CoreLevelCompatibilityLayer.swift
//
//  Created by Hoyoun Song on 24/05/2019.
//

import Foundation
import Cocoa
class SystemLevelCompatibilityLayer {
    @discardableResult
    public func sh(_ args: String...) -> Int32 {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
    
    @discardableResult
    public func silentsh(_ args: String...) -> Int32 {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus
    }
    
    @discardableResult
    public func supersh(password: String, args: String...) -> String {
        let auth = Process()
        auth.launchPath = "/bin/echo"
        auth.arguments = [password]
        let task = Process()
        task.launchPath = "/usr/bin/sudo"
        task.arguments = args
        print("Script launched:", args.joined(separator: " "))
        let pipeBetween:Pipe = Pipe()
        auth.standardOutput = pipeBetween
        task.standardInput = pipeBetween
        let pipeToMe = Pipe()
        task.standardOutput = pipeToMe
        task.standardError = pipeToMe
        auth.launch()
        task.launch()
        task.waitUntilExit()
        let data = pipeToMe.fileHandleForReading.readDataToEndOfFile()
        let output : String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        return output
    }
    
    // @discardableResult
    //public func runmpkg(password: String, args: String...) -> String{
    public func runmpkg(_ args: String...){
        //let output = supersh(password: password, args: "/usr/local/bin/mpkg", args[0], args[1], args[2])
        //return output
        sh("/usr/local/bin/mpkg", args[0], args[1], args[2])
    }
    
    public func checkFile(pathway: String) -> Bool {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: pathway) {
            return true
        } else {
            var isDir : ObjCBool = true
            if fileManager.fileExists(atPath: pathway, isDirectory:&isDir) {
                return true
            } else {
                return false
            }
        }
    }
    
    @discardableResult
    public func copyFile(source: String, destination: String, doSU: Bool, password: String?) -> Bool {
        if checkFile(pathway: source){
            if doSU {
                supersh(password: password!, args: "cp", "-r", source, destination)
            }else{
                sh("cp", "-r", source, destination)
            }
        }else{
            print("No such file...")
            return false
        }
        if checkFile(pathway: destination) {
            return true
        }else{
            return false
        }
    }
    
    @discardableResult
    public func deleteFile(path: String, doSU: Bool, password: String? ) -> Bool {
        if checkFile(pathway: path){
            if doSU {
                supersh(password: password!, args: "rm", "-rf", path)
            }else{
                sh("rm", "-rf", path)
            }
        }
        if checkFile(pathway: path){
            return false
        }else{
            return true
        }
    }
    
    @discardableResult
    public func download(address: String, output: String, doSU: Bool, password: String? ) -> Bool {
        if doSU {
            supersh(password: password!, args: "curl", "-Ls", address, "-o", output)
        }else{
            sh("curl", "-Ls", address, "-o", output)
        }
        if checkFile(pathway: output){
            return false
        }else{
            return true
        }
    }
    
    public func getUsername() -> String? {
        return NSUserName()
    }
    
    public func readFile(pathway: String) -> String {
        if !checkFile(pathway: pathway) {
            return "returned:nofile"
        }else{
            do{
                let filepath = URL.init(fileURLWithPath: pathway)
                let content = try String(contentsOf: filepath, encoding: .utf8)
                return content
            }catch{
                exit(1)
            }
        }
    }
    
    public func writeFile(pathway: String, content: String) {
        let file = pathway
        let text = content
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(file)
            do {
                try text.write(to: fileURL, atomically: false, encoding: .utf8)
            }catch {
                let Graphics: GraphicComponents = GraphicComponents()
                Graphics.msgBox_errorMessage(title: "File Writing Error", contents: "There was a problem while writing file: " + pathway)
            }
        }
    }
    
    public func getHomeDirectory() -> String{
        let fsutil = FileManager.default
        var homeurl = fsutil.homeDirectoryForCurrentUser.absoluteString
        if homeurl.contains("file://"){
            homeurl = homeurl.replacingOccurrences(of: "file://", with: "")
        }
        return homeurl
    }
    
}

class GraphicComponents {
    @discardableResult
    public func msgBox_errorMessage(title: String, contents: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = contents
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Dismiss")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    // Info Message Box
    @discardableResult
    public func msgBox_Message(title: String, contents: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = contents
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Dismiss")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    public func msgBox_QMessage(title: String, contents: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = contents
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Yes")
        alert.addButton(withTitle: "No")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
    @discardableResult
    public func msgBox_criticalSystemErrorMessage(errorType: String, errorCode: String, errorClass: String, errorLine: String, errorMethod: String, errorMessage: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = "Critical Error"
        alert.informativeText = "Critical Error: " + errorCode + "\nError Code: " + errorCode + "\nError Class: " + errorClass + "\nError Line: " + errorLine + "\nError Method: " + errorMethod + "\nError Message: " + errorMessage
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Dismiss")
        return alert.runModal() == .alertFirstButtonReturn
    }
    
}

class KeyCodeTranslator {
    func translate (_ args: [String] ) -> String {
        var output = ""
        var loop = 0
        while loop < args.count {
            output += convert(Int(args[loop]) ?? 0)
            loop += 1
        }
        return output
    }
    
    func convert (_ a: Int) -> String {
        switch a {
        case 0:
            return "a"
        case 11:
            return "b"
        case 8:
            return "c"
        case 2:
            return "d"
        case 14:
            return "e"
        case 3:
            return "f"
        case 5:
            return "g"
        case 4:
            return "h"
        case 34:
            return "i"
        case 38:
            return "j"
        case 40:
            return "k"
        case 37:
            return "l"
        case 46:
            return "m"
        case 45:
            return "n"
        case 31:
            return "o"
        case 35:
            return "p"
        case 12:
            return "q"
        case 15:
            return "r"
        case 1:
            return "s"
        case 17:
            return "t"
        case 32:
            return "u"
        case 9:
            return "v"
        case 13:
            return "w"
        case 7:
            return "x"
        case 16:
            return "y"
        case 6:
            return "z"
        case 18:
            return "1"
        case 19:
            return "2"
        case 20:
            return "3"
        case 21:
            return "4"
        case 23:
            return "5"
        case 22:
            return "6"
        case 26:
            return "7"
        case 28:
            return "8"
        case 25:
            return "9"
        case 29:
            return "0"
        case 47:
            return "."
        case 24:
            return "="
        default:
            return "///"
        }
    }
}

//
//class FakeViewController {
//    override func removehere-viewDidLoad() {
//        NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
//            if self.myKeyDown(with: $0) {
//                return nil
//            } else {
//                return $0
//            }
//        }
//    }
//    func myKeyDown(with event: NSEvent) -> Bool {
//       guard let locWindow = self.view.window,
//NSApplication.shared.keyWindow === locWindow else { return false }
//if Int(event.keyCode) == 0 {
//    
//}
//return true
//    }
//}
