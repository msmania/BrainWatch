//
//  EEGData.swift
//  BrainWatch
//
//  Created by Toshihito Kikuchi on 7/11/16.
//  Copyright © 2016 jp.co.tokikuch. All rights reserved.
//

import UIKit

class EEGSnapshot {
    enum SnapshotField { case signal, att, med, delta, theta, lowA, highA, lowB, highB, lowG, midG }

    struct Field {
        var key: SnapshotField
        var label: String
        var value: Int32
        var bgColor: UIColor
        var textColor: UIColor
        var labelColor: UIColor
    }

    private(set) var data: [Field] = [
        Field(key: .signal, label: "sig", value: 0, bgColor: UIColor.blackColor(), textColor: UIColor.whiteColor(), labelColor: UIColor.whiteColor()),
        Field(key: .att, label: "att", value: 0, bgColor: UIColor.redColor(), textColor: UIColor.whiteColor(), labelColor: UIColor.blackColor()),
        Field(key: .med, label: "med", value: 0, bgColor: UIColor.blueColor(), textColor: UIColor.whiteColor(), labelColor: UIColor.blackColor()),
        Field(key: .delta, label: "δ", value: 0, bgColor: UIColor.whiteColor(), textColor: UIColor.blackColor(), labelColor: UIColor.blackColor()),
        Field(key: .theta, label: "θ", value: 0, bgColor: UIColor.whiteColor(), textColor: UIColor.blackColor(), labelColor: UIColor.blackColor()),
        Field(key: .lowA, label: "l-α", value: 0, bgColor: UIColor.whiteColor(), textColor: UIColor.blackColor(), labelColor: UIColor.blackColor()),
        Field(key: .highA, label: "h-α", value: 0, bgColor: UIColor.whiteColor(), textColor: UIColor.blackColor(), labelColor: UIColor.blackColor()),
        Field(key: .lowB, label: "l-β", value: 0, bgColor: UIColor.whiteColor(), textColor: UIColor.blackColor(), labelColor: UIColor.blackColor()),
        Field(key: .highB, label: "h-β", value: 0, bgColor: UIColor.whiteColor(), textColor: UIColor.blackColor(), labelColor: UIColor.blackColor()),
        Field(key: .lowG, label: "l-γ", value: 0, bgColor: UIColor.whiteColor(), textColor: UIColor.blackColor(), labelColor: UIColor.blackColor()),
        Field(key: .midG, label: "m-γ", value: 0, bgColor: UIColor.whiteColor(), textColor: UIColor.blackColor(), labelColor: UIColor.blackColor()),
    ]

    private var reverseMap: [SnapshotField: Int] = Dictionary()

    init() {
        for (i, field) in data.enumerate() {
            reverseMap.updateValue(i, forKey: field.key)
        }
    }

    func setSigleValue(field: SnapshotField, value: Int32) {
        if let idx = reverseMap[field] {
            data[idx].value = value
        }
    }

    func setEEGValues(eeg: TGSEEGPower) {
        data[reverseMap[.lowA]!].value = eeg.lowAlpha
        data[reverseMap[.lowB]!].value = eeg.lowBeta
        data[reverseMap[.lowG]!].value = eeg.lowGamma
        data[reverseMap[.highA]!].value = eeg.highAlpha
        data[reverseMap[.highB]!].value = eeg.highBeta
        data[reverseMap[.midG]!].value = eeg.middleGamma
        data[reverseMap[.delta]!].value = eeg.delta
        data[reverseMap[.theta]!].value = eeg.theta
    }

    func getCsvHeader() -> String {
        return data.map{$0.label}.joinWithSeparator(",")
    }

    func getCsvLine() -> String {
        return data.map{String($0.value)}.joinWithSeparator(",")
    }
}

class EEGCell: UICollectionViewCell {
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelValue: UILabel!

    func updateUI(eeg: EEGSnapshot.Field) {
        self.backgroundColor = eeg.bgColor
        labelTitle.text = eeg.label
        labelTitle.textColor = eeg.labelColor
        labelValue.text = String(eeg.value)
        labelValue.textColor = eeg.textColor
    }
}
