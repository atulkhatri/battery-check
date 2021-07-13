//
//  Constants.swift
//  BatteryCheck
//
//  Created by Atul Khatri on 13/07/21.
//

import Foundation

struct Constants {
	static let defaultLowBatteryPercentage = 12
	static let defaultFullBatteryPercentage = 100
	static let defaultPollingDuration = 30
	
	struct NotificationName {
		static let timerReset = "resetTimer"
	}
	
	struct Keys {
		static let serviceKey = "serviceKey"
		static let lowBatteryPercentage = "lowBatteryPercentage"
		static let fullBatteryPercentage = "fullBatteryPercentage"
		static let pollingDuration = "pollingDuration"
	}
}
