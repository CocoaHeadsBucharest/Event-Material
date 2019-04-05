//
//  NotificationViewController.swift
//  Custom UI
//
//  Created by Marius Constantinescu on 02/04/2019.
//  Copyright © 2019 Greener Pastures. All rights reserved.
//

import UIKit
import UserNotifications
import UserNotificationsUI
import MapKit

class NotificationViewController: UIViewController, UNNotificationContentExtension {

	@IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any required interface initialization here.
    }
    
    func didReceive(_ notification: UNNotification) {
		let userInfo = notification.request.content.userInfo
		guard let latitude = userInfo["latitude"] as? CLLocationDistance,
			let longitude = userInfo["longitude"] as? CLLocationDistance,
			let radius = userInfo["radius"] as? CLLocationDistance else {
				return
		}
		let location = CLLocation(latitude: latitude, longitude: longitude)
		let region = MKCoordinateRegion(center: location.coordinate,
										latitudinalMeters: radius,
										longitudinalMeters: radius)
		mapView.setRegion(region, animated: false)
    }

}
