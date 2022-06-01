//
//  ViewController.swift
//  RingerAlert 2015
//
//  Created by videoadventures imac on 1/18/15.
//  Copyright (c) 2015 videoadventures. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreLocation

class ViewController: UIViewController, ESTBeaconManagerDelegate, UIAlertViewDelegate {
    var beaconManager:ESTBeaconManager = ESTBeaconManager()
    @IBOutlet weak var proximityLabel: UILabel!
    @IBOutlet weak var numberOfBeaconsLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var immediateView: UIImageView!
    @IBOutlet weak var nearView: UIImageView!
    @IBOutlet weak var farView: UIImageView!
    var images: [UIImage] = []
    var dictionary = [Int: String]()
    var beaconMinor: Int!
    var beaconName : String = "This is the name of a beacon"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    //Load Images
        let imageNames = ["RadarSplash_0.jpg", "RadarSplash_1.jpg", "RadarSplash_2.jpg", "RadarSplash_3.jpg", "RadarSplash_4.jpg", "RadarSplash_5.jpg", "RadarSplash_6.jpg", "RadarSplash_7.jpg", "RadarSplash_8.jpg", "RadarSplash_9.jpg", "RadarSplash_10.jpg", "RadarSplash_11.jpg", "RadarSplash_12.jpg", "RadarSplash_13.jpg", "RadarSplash_14.jpg", "RadarSplash_15.jpg", "RadarSplash_16.jpg", "RadarSplash_17.jpg", "RadarSplash_18.jpg", "RadarSplash_19.jpg", "RadarSplash_20.jpg", "RadarSplash_21.jpg", "RadarSplash_22.jpg", "RadarSplash_23.jpg", "RadarSplash_25.jpg", "RadarSplash_26.jpg", "RadarSplash_27.jpg"]
        
        //Put images in array
        for count in 0...27 {
            var stringName : String = "RadarSplash_\(count).jpg"
            var pictures = UIImage(named: stringName)
            images.append(pictures!)
        }
        
        //Animate images
        imageView.animationImages = images
        imageView.animationDuration = 2.0
        imageView.startAnimating()
        
        //Set markers opacity
        self.farView.alpha = 0
        self.nearView.alpha = 0
        self.immediateView.alpha = 0

        
    
    //create uuid
        let uuid = NSUUID(UUIDString: "B9407F30-F5F8-466E-AFF9-25556B57FE6D")
    
    //set up beacon manager
        beaconManager.delegate = self

    //set up beacon region
        let region = ESTBeaconRegion(proximityUUID: uuid, major: 15401, identifier: "Location")

    //request authorazation always
        if (ESTBeaconManager.authorizationStatus() != CLAuthorizationStatus.AuthorizedWhenInUse) {
            beaconManager.requestAlwaysAuthorization()
        }
       
    //start monitoring
        beaconManager.startMonitoringForRegion(region)

    //start ranging
        //beaconManager.startRangingBeaconsInRegion(region)
        beaconManager.startRangingBeaconsInRegion(region)
        
    }
    
    //checks for region failure
    func beaconManager(manager: ESTBeaconManager!, monitoringDidFailForRegion region: ESTBeaconRegion!, withError error: NSError!) {
        println("Did Fail: manager: \(manager) region: \(region) error: \(error)")
    }
    
    //checks permission status
    func beaconManager(manager: ESTBeaconManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        println("Status: \(status)")
    }
    
    //beacon manager did enter region
    
    func beaconManager(manager: ESTBeaconManager!, didEnterRegion region: ESTBeaconRegion!) {
        let notification: UILocalNotification = UILocalNotification()
        notification.alertAction = "OK"
        notification.alertBody = "You have entered a region that has requested you silence your iPhone. Thanks."
        notification.soundName = UILocalNotificationDefaultSoundName
        println("Entered a region")
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
    
    //beacon manager did exit region
    func beaconManager(manager: ESTBeaconManager!, didExitRegion region: ESTBeaconRegion!) {
        let notification: UILocalNotification = UILocalNotification()
        notification.alertAction = "OK"
        notification.alertBody = "You have exited the RingerAlert region. Please remember to re-enable your ringer. Thanks."
        notification.soundName = UILocalNotificationDefaultSoundName
        println("Entered a region")
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
    
    //ranging code
    func beaconManager(manager: ESTBeaconManager!, didRangeBeacons beacons: [AnyObject]!, inRegion region: ESTBeaconRegion!) {
        if beacons.count == 1 {
            numberOfBeaconsLabel.text = "IN REGION: 1 BEACON"
        } else {
            numberOfBeaconsLabel.text = "IN REGION: \(beacons.count) BEACONS"
        }
        
        //checks for occurence of beacon minors in the dictionary
        if beacons.count > 0 {
            println(dictionary)
            let firstBeacon = beacons[0] as ESTBeacon
            beaconMinor = firstBeacon.minor as Int
            var inDict: Bool = false
            for minorKey in dictionary.keys {
                if beaconMinor == minorKey {
                    inDict = true
                }
            }
            
            if inDict == false {
                dictionary[beaconMinor] = ""
                newNameAlert()
            }
        
            let prox = firstBeacon.proximity
            
        
            switch prox {
            case CLProximity.Far:
                //println("Far")
                //println(firstBeacon.rssi)
                proximityLabel.text = "CURRENT ZONE: Far"
                UIView.animateWithDuration(1.0, animations: { () -> Void in
                    self.farView.alpha = 1.0
                    self.nearView.alpha = 0.0
                    self.immediateView.alpha = 0.0
                })
                break
                
            case CLProximity.Near:
                //println("near")
               // println(firstBeacon.rssi)
                proximityLabel.text = "CURRENT ZONE: Near"
                UIView.animateWithDuration(1.0, animations: { () -> Void in
                    self.nearView.alpha = 1.0
                    self.immediateView.alpha = 0.0
                    self.farView.alpha = 0.0
                })
                break
                
            case CLProximity.Immediate:
                //println("immediate")
               // println(firstBeacon.rssi)
                proximityLabel.text = "CURRENT ZONE: Immediate"
                UIView.animateWithDuration(1.0, animations: { () -> Void in
                    self.immediateView.alpha = 1.0
                    self.nearView.alpha = 0.0
                    self.farView.alpha = 0.0
                })
                break
                
            case CLProximity.Unknown:
                //println("unknown")
                proximityLabel.text = "CURRENT ZONE: Unknown"
                UIView.animateWithDuration(1.0, animations: { () -> Void in
                    self.immediateView.alpha = 0.0
                    self.nearView.alpha = 0.0
                    self.farView.alpha = 0.0
                })
                break
            default:
                break
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func newNameAlert() {
        let nameAlert: UIAlertView = UIAlertView(title: "New Region", message: "You have entered a new ringer free region. Please input a name for this region.", delegate: self, cancelButtonTitle: "Add")
        nameAlert.alertViewStyle = UIAlertViewStyle.PlainTextInput
        nameAlert.show()
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            if !alertView.textFieldAtIndex(0)!.text.isEmpty {
                beaconName = alertView.textFieldAtIndex(0)!.text
                dictionary[beaconMinor] = beaconName
            } else {
                newNameAlert()
            }
        }
    }
}