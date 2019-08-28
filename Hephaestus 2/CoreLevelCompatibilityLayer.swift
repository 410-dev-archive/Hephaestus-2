//
//  CoreLevelCompatibilityLayer.swift
//
//  Created by Hoyoun Song on 24/05/2019.
//

// VERSION 32

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
    
    public func getUsername() -> String? {
        return NSUserName()
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
