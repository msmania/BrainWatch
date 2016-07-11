//
//  ViewController.swift
//  BrainWatch
//
//  Created by Toshihito Kikuchi on 7/10/16.
//  Copyright © 2016 jp.co.tokikuch. All rights reserved.
//

import UIKit

class ViewController: UIViewController, TGStreamDelegate {
    enum State { case Disconnected, Connected, Recording }
    var state = State.Disconnected
    var tgsInstance = TGStream.sharedInstance()
    var eegWriter = EEGWriter(subDirectory: "/eeg")
    let isOffline = true
    var lastPoorSignal: Int32 = 200

    @IBOutlet weak var buttonStart: UIButton!
    @IBOutlet weak var textName: UITextField!
    @IBOutlet weak var textScene: UITextField!
    
    func logInfo(message: String) {
        print(message)
    }
    
    func logError(message: String) {
        print(message)
    }
    
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "BrainWatch",
                                                message: message,
                                                preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tgsInstance.delegate = self
        logInfo(tgsInstance.getVersion())
        updateUI()
        textName.text = UIDevice.currentDevice().name
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateUI() {
        var buttonLabel = ""
        switch (state) {
        case .Disconnected:
            buttonLabel = "Connect"
        case .Connected:
            buttonLabel = "Start Recording"
        case .Recording:
            buttonLabel = "Stop Recording"
        }
        buttonStart.setTitle(buttonLabel, forState: .Normal)
    }
    
    func connectToSample() {
        if let filepath = NSBundle.mainBundle().pathForResource("sample_data", ofType: "txt") {
            logInfo(filepath)
            tgsInstance.initConnectWithFile(filepath)
        }
        else {
            showAlert("Sample file does not exist")
        }
    }
    
    func onDataReceived(datatype: Int, data: Int32, obj: NSObject!, deviceType: DEVICE_TYPE) {
        switch (datatype) {
        case Int(MindDataType.CODE_POOR_SIGNAL.rawValue):
            if data != lastPoorSignal {
                logInfo(String(format: "signal: %d -> %d", lastPoorSignal, data));
                lastPoorSignal = data
            }
        case Int(MindDataType.CODE_EEGPOWER.rawValue):
            if let eeg = obj as? TGSEEGPower {
                if state == .Recording {
                    eegWriter?.write(lastPoorSignal, eeg: eeg)
                }
            }
        case Int(MindDataType.CODE_RAW.rawValue):
            break
        case Int(MindDataType.CODE_ATTENTION.rawValue):
            break
        case Int(MindDataType.CODE_MEDITATION.rawValue):
            break
        default:
            logInfo(String(format: "datatype = %d", datatype))
        }
    }
    
    func onStatesChanged(connectionState: ConnectionStates) {
        var needUpdateUI = false
        switch (connectionState) {
        case .STATE_ERROR:
            showAlert("Connection error")
            if !isOffline {
                tgsInstance.tearDownAccessorySession()
            }
            state = .Disconnected
            needUpdateUI = true
        case .STATE_WORKING:
            state = .Connected
            needUpdateUI = true
        default:
            logInfo(String(format: "connectionState = %d", connectionState.rawValue))
            break
        }
        if needUpdateUI {
            updateUI()
        }
    }
    
    @IBAction func onButtonStart(sender: UIButton) {
        switch (state) {
        case .Disconnected:
            if isOffline {
                connectToSample()
            }
            else {
                tgsInstance.initConnectWithAccessorySession()
            }
        case .Connected:
            eegWriter?.start(textName.text ?? "John", activity: textScene.text ?? "Driving")
            tgsInstance.setRecordStreamFilePath()
            tgsInstance.startRecordRawData()
            state = .Recording
        case .Recording:
            tgsInstance.stopRecordRawData()
            eegWriter?.stop()
            state = .Connected
        }
        updateUI()
    }
}

