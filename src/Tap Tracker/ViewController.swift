//
//  ViewController.swift
//  Tap Tracker
//
//  Created by Kyle Jessup on 2015-10-22.
//	Copyright (C) 2015 PerfectlySoft, Inc.
//
//===----------------------------------------------------------------------===//
//
// This source file is part of the Perfect.org open source project
//
// Copyright (c) 2015 - 2016 PerfectlySoft Inc. and the Perfect project authors
// Licensed under Apache License v2.0
//
// See http://perfect.org/licensing.html for license information
//
//===----------------------------------------------------------------------===//
//


import UIKit
import MapKit

// adjust these to match whatever the server is listening on
// these are the default values which should work unless the server has been changed
let END_POINT_HOST = "localhost"
let END_POINT_PORT = 8181

let END_POINT = "http://\(END_POINT_HOST):\(END_POINT_PORT)/TapTracker"

class ViewController: UIViewController, CLLocationManagerDelegate {

	var selectedLocation: CLLocation? = nil
	let locationManager: CLLocationManager
	
	var timeStr = ""
	var lat = 0.0, long = 0.0
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		self.locationManager = CLLocationManager()
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	required init?(coder aDecoder: NSCoder) {
		self.locationManager = CLLocationManager()
		super.init(coder: aDecoder)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.title = "Tap Tracker"
		self.locationManager.delegate = self
		if self.locationManager.respondsToSelector(#selector(CLLocationManager.requestWhenInUseAuthorization)) {
			self.locationManager.requestWhenInUseAuthorization()
		}
		self.locationManager.startUpdatingLocation()
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let loc = locations.first {
			self.selectedLocation = loc
		}
	}
	
    @IBAction
    func buttonPressed(Sender: AnyObject) {
        if let loc = self.selectedLocation {
            
            let lat = loc.coordinate.latitude
            let long = loc.coordinate.longitude
            
            let postBody = "lat=\(lat)&long=\(long)"
            
            let req = NSMutableURLRequest(URL: NSURL(string: END_POINT)!)
            req.HTTPMethod = "POST"
            req.HTTPBody = postBody.dataUsingEncoding(NSUTF8StringEncoding)
            
            let session = NSURLSession.sharedSession()
            
            let task = session.dataTaskWithRequest(req, completionHandler: {
                (d:NSData?, res:NSURLResponse?, e:NSError?) -> Void in
                if let _ = e {
                    print("Request failed with error \(e!)")
                } else {
                    guard let data = d else { return }
                    
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
                        print("\(#function) : \(#line) : RESPONSE JSON : \(json)")
                        if let jsonArray = json["resultSets"] as? [AnyObject] {
                            if let result = jsonArray.first {
                                if let timeString = result["time"] as? String,
                                    lat = result["lat"] as? Double,
                                    long = result["long"] as? Double {
                                    self.timeStr = timeString
                                    self.lat = lat
                                    self.long = long
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.performSegueWithIdentifier("showMap", sender: self)
                                    })
                                }
                            }
                        }
                    } catch {
                        print("\(#function) : \(#line) : ERROR: \(error)")
                    }
                }
            })
            
            task.resume()
            
        } else {
            // no location
            
            let alert = UIAlertController(title: "No Location", message: "Ensure that location services are available and try again.", preferredStyle: .Alert)
            let action = UIAlertAction(title: "OK", style: .Default) {
                (a:UIAlertAction) -> Void in
            }
            alert.addAction(action)
            self.presentViewController(alert, animated: true) { }
        }
    }
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if let dest = segue.destinationViewController as? MapViewController {
			dest.timeStr = self.timeStr
			dest.lat = self.lat
			dest.long = self.long
		}
	}

}

