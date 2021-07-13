//
//  ViewController.swift
//  BatteryCheck
//
//  Created by Atul Khatri on 05/05/21.
//

import Cocoa
import UserNotifications

class ViewController: NSViewController {
    @IBOutlet weak var textfield: NSTextField!
    @IBOutlet weak var lowPopUpButton: NSPopUpButton!
    @IBOutlet weak var fullPopUpButton: NSPopUpButton!
    @IBOutlet weak var pollingTextfield: NSTextField!
    
    var serviceKey = ""
	var lowBatteryPercentage = Constants.defaultLowBatteryPercentage
	var fullBatteryPercentage = Constants.defaultFullBatteryPercentage
	var pollingDuration = Constants.defaultPollingDuration

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        loadConfiguration()
        askNotificationPermission()
		NotificationCenter.default.post(name: Notification.Name(Constants.NotificationName.timerReset), object: nil)
    }
    
    private func setupView() {
        lowPopUpButton.removeAllItems()
        fullPopUpButton.removeAllItems()
        for index in 1...100 {
            lowPopUpButton.addItem(withTitle: String(index))
            fullPopUpButton.addItem(withTitle: String(index))
        }
        lowPopUpButton.selectItem(at: lowBatteryPercentage-1)
        fullPopUpButton.selectItem(at: fullBatteryPercentage-1)
    }
    
    private func askNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            // Ignore the result
        }
    }
    
    private func loadConfiguration() {
		if let key = UserDefaults.standard.object(forKey: Constants.Keys.serviceKey) as? String {
            serviceKey = key
            textfield.stringValue = key
        }
		if let low = UserDefaults.standard.object(forKey: Constants.Keys.lowBatteryPercentage) as? Int {
            lowBatteryPercentage = low
            lowPopUpButton.selectItem(at: low-1)
        }
		if let full = UserDefaults.standard.object(forKey: Constants.Keys.fullBatteryPercentage) as? Int {
            fullBatteryPercentage = full
            fullPopUpButton.selectItem(at: full-1)
        }
		if let duration = UserDefaults.standard.object(forKey: Constants.Keys.pollingDuration) as? Int {
            pollingDuration = duration
            pollingTextfield.stringValue = String(duration)
        }
    }
    
    private func saveConfiguration() {
        if textfield.stringValue.isEmpty ||
            pollingTextfield.integerValue < pollingDuration {
            let alert = NSAlert()
            if textfield.stringValue.isEmpty {
                alert.messageText = "Please enter service key"
            } else {
                alert.messageText = "Please increase polling duration (minimum \(pollingDuration) seconds)"
            }
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }
        serviceKey = textfield.stringValue
        pollingDuration = pollingTextfield.integerValue
        lowBatteryPercentage = lowPopUpButton.indexOfSelectedItem+1
        fullBatteryPercentage = fullPopUpButton.indexOfSelectedItem+1
		UserDefaults.standard.setValue(serviceKey, forKey: Constants.Keys.serviceKey)
		UserDefaults.standard.setValue(lowBatteryPercentage, forKey: Constants.Keys.lowBatteryPercentage)
		UserDefaults.standard.setValue(fullBatteryPercentage, forKey: Constants.Keys.fullBatteryPercentage)
		UserDefaults.standard.setValue(pollingDuration, forKey: Constants.Keys.pollingDuration)
    }
    
    @IBAction func didTapSaveButton(_ sender: Any) {
        saveConfiguration()
		NotificationCenter.default.post(name: Notification.Name(Constants.NotificationName.timerReset), object: nil)
        view.window?.close()
    }
    
    @IBAction func didTapQuitButton(_ sender: Any) {
        NSApplication.shared.terminate(sender)
    }
}
