//
//  BackgroundService.swift
//  BatteryCheck
//
//  Created by Atul Khatri on 07/05/21.
//

import Foundation
import UserNotifications

class BackgroundService {
    var timer: Timer? = nil
    var serviceKey = ""
	var lowBatteryPercentage = Constants.defaultLowBatteryPercentage
	var fullBatteryPercentage = Constants.defaultFullBatteryPercentage
	var pollingDuration = Constants.defaultPollingDuration
    
    init() {
        resetTimer()
		NotificationCenter.default.addObserver(self, selector: #selector(resetTimer), name: Notification.Name(Constants.NotificationName.timerReset), object: nil)
    }
    
    private func loadConfiguration() {
		if let key = UserDefaults.standard.object(forKey: Constants.Keys.serviceKey) as? String {
            serviceKey = key
        }
		if let low = UserDefaults.standard.object(forKey: Constants.Keys.lowBatteryPercentage) as? Int {
            lowBatteryPercentage = low
        }
		if let full = UserDefaults.standard.object(forKey: Constants.Keys.fullBatteryPercentage) as? Int {
            fullBatteryPercentage = full
        }
		if let duration = UserDefaults.standard.object(forKey: Constants.Keys.pollingDuration) as? Int {
            pollingDuration = duration
        }
    }

    
    @objc private func resetTimer() {
        loadConfiguration()
        if timer != nil {
            timer?.invalidate()
            timer = nil
        }
        guard !serviceKey.isEmpty else { return }
        executeTimer()
        timer = Timer(timeInterval: TimeInterval(pollingDuration), repeats: true, block: { [weak self] timer in
            self?.executeTimer()
        })
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func executeTimer() {
        let percentage = self.getBatteryPercentage()
        print("### Current Percentage: \(percentage)")
        if percentage <= self.lowBatteryPercentage && !self.isCharging() {
            self.performAction(type: .batteryLow)
        } else if percentage >= self.fullBatteryPercentage && (self.isCharging() || self.isCharged()) {
            self.performAction(type: .batteryFull)
        }
    }

    private func performAction(type: ActionType) {
        let trigger = type.rawValue
        let session = URLSession.shared
        guard let url = URL(string: "https://maker.ifttt.com/trigger/\(trigger)/with/key/\(serviceKey)") else { return }
        let task = session.dataTask(with: url, completionHandler: { data, response, error in
            print("### response: \(String(describing: response)), error: \(String(describing: error))")
        })
        task.resume()
        
        showNotification(type: type)
    }
    
    private func showNotification(type: ActionType) {
        let notificationCenter = UNUserNotificationCenter.current();
        notificationCenter.getNotificationSettings
           { (settings) in
           if settings.authorizationStatus == .authorized
               {
               //print ("Notifications Still Allowed");
               // build the banner
               let content = UNMutableNotificationContent();
            content.title = "Battery level reached \(self.getBatteryPercentage())"
            content.body = type == .batteryLow ? "Turned on charging!" : "Turned off charging!"
//               if sound == "YES" {content.sound = UNNotificationSound.default}
               // could add .badge
               // could add .userInfo

               // define when banner will appear - this is set to 1 second - note you cannot set this to zero
              let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false);

               // Create the request
               let uuidString = UUID().uuidString ;
               let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger);

              // Schedule the request with the system.
              notificationCenter.add(request, withCompletionHandler:
                 { (error) in
                 if error != nil
                     {
                     // Something went wrong
                     }
                  })
              //print ("Notification Generated");
             }
        }
    }
    
    private func isCharging() -> Bool {
        let output = getBatteryInfo()
        let batteryArray = output.components(separatedBy: ";")
        let state = batteryArray[1].trimmingCharacters(in: NSCharacterSet.whitespaces).lowercased()
        return state == "charging"
    }
    
    private func isCharged() -> Bool {
        let output = getBatteryInfo()
        let batteryArray = output.components(separatedBy: ";")
        let state = batteryArray[1].trimmingCharacters(in: NSCharacterSet.whitespaces).lowercased()
        return state == "charged"
    }
    
    private func getBatteryPercentage() -> Int {
        let output = getBatteryInfo()
        let batteryArray = output.components(separatedBy: ";")
        let percent = String.init(batteryArray[0].components(separatedBy: ")")[1].trimmingCharacters(in: NSCharacterSet.whitespaces).dropLast())
        return Int(percent) ?? 0
    }

    private func checkBatteryStatus() {
        let output = getBatteryInfo()
        let batteryArray = output.components(separatedBy: ";")
        let source = output.components(separatedBy: "'")[1]
        let state = batteryArray[1].trimmingCharacters(in: NSCharacterSet.whitespaces).capitalized
        let percent = String.init(batteryArray[0].components(separatedBy: ")")[1].trimmingCharacters(in: NSCharacterSet.whitespaces).dropLast())
        var remaining = String.init(batteryArray[2].dropFirst().split(separator: " ")[0])
        if remaining == "(no" {
            remaining = "Calculating"
        }
        print("### -> \([source, state, percent, remaining])")
    }

    private func getBatteryInfo() -> String {
        let task = Process()
        let pipe = Pipe()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["-g", "batt"]
        task.standardOutput = pipe
        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
        return output
    }
}

enum ActionType: String {
    case batteryLow = "battery_low"
    case batteryFull = "battery_full"
}
