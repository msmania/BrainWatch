//
//  ViewController.swift
//  BrainWatch
//
//  Created by Toshihito Kikuchi on 7/10/16.
//  Copyright © 2016 jp.co.tokikuch. All rights reserved.
//
// http://stackoverflow.com/questions/31735228/how-to-make-a-simple-collection-view-with-swift
//

import UIKit

class ViewController: UIViewController, TGStreamDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UITextFieldDelegate {
    enum State { case Disconnected, Connected, Recording }
    var state = State.Disconnected
    var tgsInstance = TGStream.sharedInstance()
    var eegWriter = EEGWriter(subDirectory: "/eeg")
    let isOffline = false
    let reuseIdentifier = "cell"
    var eegSnapshot = EEGSnapshot()

    @IBOutlet weak var buttonStart: UIButton!
    @IBOutlet weak var textName: UITextField!
    @IBOutlet weak var textScene: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    
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
        
        tgsInstance.delegate = self
        textName.delegate = self
        textScene.delegate = self

        logInfo(tgsInstance.getVersion())
        updateUI()
        textName.text = UIDevice.currentDevice().name
        NSTimer.scheduledTimerWithTimeInterval(1,
                                               target: self,
                                               selector: #selector(self.onTimer),
                                               userInfo: nil,
                                               repeats: true)

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
            eegSnapshot.setSigleValue(.signal, value: data)
        case Int(MindDataType.CODE_EEGPOWER.rawValue):
            if let eeg = obj as? TGSEEGPower {
                //logInfo("delta = \(eeg.delta)")
                eegSnapshot.setEEGValues(eeg)
            }
        case Int(MindDataType.CODE_RAW.rawValue):
            break
        case Int(MindDataType.CODE_ATTENTION.rawValue):
            //logInfo("att = \(data)")
            eegSnapshot.setSigleValue(.att, value: data)
        case Int(MindDataType.CODE_MEDITATION.rawValue):
            //logInfo("med = \(data)")
            eegSnapshot.setSigleValue(.med, value: data)
            // SDK sends events in the order of CODE_EEGPOWER, CODE_ATTENTION, and CODE_MEDITATION
            // in a window of one second.  Thus, we write an event at CODE_MEDITATION.
            if state == .Recording {
                eegWriter?.write(eegSnapshot)
            }
        default:
            logInfo(String(format: "datatype = %d", datatype))
        }
    }
    
    func onStatesChanged(connectionState: ConnectionStates) {
        var needUpdateUI = false
        logInfo(String(format: "connectionState = %d", connectionState.rawValue))
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
        hideKeyboard()
        switch (state) {
        case .Disconnected:
            if isOffline {
                connectToSample()
            }
            else {
                tgsInstance.initConnectWithAccessorySession()
            }
        case .Connected:
            eegWriter?.start(textName.text ?? "John", activity: textScene.text ?? "Driving", eeg: eegSnapshot)
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

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.eegSnapshot.data.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! EEGCell
        cell.updateUI(eegSnapshot.data[indexPath.item])
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        hideKeyboard()
    }

    func onTimer() {
        collectionView.reloadData()
    }

    private func hideKeyboard() {
        textName.resignFirstResponder()
        textScene.resignFirstResponder()
    }

    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        hideKeyboard()
        return true
    }
}