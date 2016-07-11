//
//  BrainStatus.swift
//  BrainWatch
//
//  Created by Toshihito Kikuchi on 7/10/16.
//  Copyright © 2016 jp.co.tokikuch. All rights reserved.
//

import Foundation

class EEGWriter {
    var rootDirectory: String
    var fileName: String?
    
    func logInfo(message: String) {
        print(message)
    }

    func logError(message: String) {
        print(message)
    }
    
    init?(subDirectory: String) {
        let tgStream = TGStream.sharedInstance()
        print(tgStream.getVersion())
        
        self.rootDirectory = subDirectory
        self.rootDirectory = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
                                                                 NSSearchPathDomainMask.UserDomainMask,
                                                                 true)[0]
        self.rootDirectory += subDirectory

        let fileManager = NSFileManager.defaultManager()
        do {
            try fileManager.contentsOfDirectoryAtPath(self.rootDirectory)
            logInfo(self.rootDirectory);
        }
        catch {
            do {
                try fileManager.createDirectoryAtPath(self.rootDirectory,
                                                      withIntermediateDirectories: true,
                                                      attributes: nil)
            }
            catch {
                // Failed to create a directory
                logError("createDirectoryAtPath failed");
                return nil
            }
        }
    }
    
    func generateFileName() -> String {
        let formatter = NSDateFormatter()
        formatter.dateFormat = "/yyyy-MM-dd-HH-mm-ss-SSS"
        return formatter.stringFromDate(NSDate())
    }
    
    func start(user: String, activity: String) {
        fileName = generateFileName()
        writeInternal("# timestamp,poorSignal,lowAlpha,highAlpha,lowBeta,highBeta,lowGamma,middleGamma,delta,theta\n")
        writeInternal(String(format: "; User = %s\n; Activity = %s\n",
            (user as NSString).UTF8String,
            (activity as NSString).UTF8String))
    }
    
    func stop() {
        fileName = nil
    }
    
    func write(poorSignal: Int32, eeg: TGSEEGPower) {
        let now = NSDate()
        let ts = now.timeIntervalSince1970
        writeInternal(String(format: "%s,%d,%d,%d,%d,%d,%d,%d,%d,%d\n",
            (String(UInt64(ts * 1000)) as NSString).UTF8String,
            poorSignal,
            eeg.lowAlpha,
            eeg.highAlpha,
            eeg.lowBeta,
            eeg.highBeta,
            eeg.lowGamma,
            eeg.middleGamma,
            eeg.delta,
            eeg.theta))
    }
    
    private func writeInternal(line: String) {
        if fileName != nil {
            let fullPath = rootDirectory + fileName!
            if let outputStream = NSOutputStream(toFileAtPath: fullPath, append: true) {
                outputStream.open()
                let data = line.dataUsingEncoding(NSUTF8StringEncoding)!
                outputStream.write(UnsafePointer<UInt8>(data.bytes), maxLength: data.length)
                outputStream.close()
            }
        }
    }
}