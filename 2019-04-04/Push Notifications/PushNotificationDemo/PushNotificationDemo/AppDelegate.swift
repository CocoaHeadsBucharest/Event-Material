//
//  AppDelegate.swift
//  PushNotificationDemo
//
//  Created by Marius Constantinescu on 27/03/2019.
//  Copyright © 2019 Greener Pastures. All rights reserved.
//

import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

	var window: UIWindow?

	private let logWaterCategoryIdentifier = "LogWater"
	private enum LogWaterActionIdentifier: String {
		case yes, no
	}

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.

		UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .sound, .alert]) { granted, _ in
			guard granted else { return }

			UNUserNotificationCenter.current().delegate = self

			DispatchQueue.main.async {
				application.registerForRemoteNotifications()
			}
		}

		return true
	}

	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		let token = deviceToken.reduce("") { $0 + String(format: "%02x", $1) }
		print(token)
		registerCustomActions()
	}

	private func registerCustomActions() {
		let yesAction = UNNotificationAction(identifier: LogWaterActionIdentifier.yes.rawValue, title: "Yes")
		let noAction = UNNotificationAction(identifier: LogWaterActionIdentifier.no.rawValue, title: "No")
		let logWaterCategory = UNNotificationCategory(identifier: logWaterCategoryIdentifier, actions: [yesAction, noAction], intentIdentifiers: [])
		UNUserNotificationCenter.current().setNotificationCategories([logWaterCategory])
	}

	// Push in foreground
	func userNotificationCenter(_ center: UNUserNotificationCenter,	willPresent notification: UNNotification, withCompletionHandler completionHandler:
		@escaping (UNNotificationPresentationOptions) -> Void) {
		completionHandler([.alert, .sound, .badge])
	}

	// Deeplinking
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		defer { completionHandler() }
		//		guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else {	return }

		// Perform actions here
		let payload = response.notification.request.content
		if let shouldShowAlert = payload.userInfo["showAlert"] as? Bool, shouldShowAlert == true {

			let alertController = UIAlertController(title: "PING!", message: "You got a notification and we're handling it in a custom way", preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
				alertController.dismiss(animated: true, completion: nil)
			}))
			window?.rootViewController?.present(alertController, animated: true)
		}

		if payload.categoryIdentifier == logWaterCategoryIdentifier, let _ = LogWaterActionIdentifier(rawValue: response.actionIdentifier) {
			print("You pressed \(response.actionIdentifier)")
		}
	}
}
