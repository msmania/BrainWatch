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
    let isOffline = false

    @IBOutlet weak var buttonStart: UIButton!
    
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
        if let eeg = obj as? TGSEEGPower {
            logInfo(String(format: "lowAlpha = %d", eeg.lowAlpha))
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
            tgsInstance.setRecordStreamFilePath()
            tgsInstance.startRecordRawData()
            state = .Recording
        case .Recording:
            tgsInstance.stopRecordRawData()
            if isOffline {
                state = .Disconnected
            }
            else {
                state = .Connected
            }
        }
        updateUI()
    }
}

