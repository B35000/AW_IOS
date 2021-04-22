//
//  LocationViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 03/01/2021.
//

import UIKit
import GoogleMaps

class LocationViewController: UIViewController, CLLocationManagerDelegate {
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var myLocationImage: UIImageView!
    var myLocationMarker: GMSMarker?
    var myLocationCircle: GMSCircle?
    
    let locationManager = CLLocationManager()
    var location_desc = ""
    var lat = 0.0
    var lng = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        do {
             // Set the map style by passing the URL of the local file.
             if let styleURL = Bundle.main.url(forResource: "style", withExtension: "json") {
                if UITraitCollection.current.userInterfaceStyle == .dark {
                    mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
                }else{
                    if let styleURL2 = Bundle.main.url(forResource: "light-style", withExtension: "json") {
                        mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL2)
                    }
                    
                }
             } else {
               NSLog("Unable to find style.json")
             }
        } catch {
             NSLog("One or more of the map styles failed to load. \(error)")
        }
                
        mapView.settings.compassButton = true
        mapView.settings.myLocationButton = false
        mapView.layer.cornerRadius = 15
        
        self.moveCamera(-1.286389, 36.817223)
        
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            self.locationManager.startUpdatingLocation()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Change `2.0` to the desired number of seconds.
               // Code you want to be delayed
//                let camera = GMSCameraPosition.camera(withLatitude: self.myLat, longitude: self.myLong, zoom: 15.0)
//                self.mapView.alpha = 1
//                self.mapView.camera = camera
            }
            
        }
        
    }
    
    
    func moveCamera(_ lat: Double,_ long: Double){
//        CATransaction.begin()
//        CATransaction.setValue(1.1, forKey: kCATransactionAnimationDuration)
        mapView.animate(to: GMSCameraPosition(latitude: lat, longitude: long, zoom: 15))
//        CATransaction.commit()
    }
    
    @IBAction func whenMyLocationTapped(_ sender: Any) {
        print("show my location tapped ------------------------")
        if lat != 0.0 && lng != 0.0 {
            self.moveCamera(self.lat, self.lng)
        }else{
            self.locationManager.requestAlwaysAuthorization()
            self.locationManager.requestWhenInUseAuthorization()
            
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.delegate = self
                self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self.locationManager.startUpdatingLocation()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Change `2.0` to the desired number of seconds.
                   // Code you want to be delayed
    //                let camera = GMSCameraPosition.camera(withLatitude: self.myLat, longitude: self.myLong, zoom: 15.0)
    //                self.mapView.alpha = 1
    //                self.mapView.camera = camera
                }
                
            }
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        
        if(self.lat == 0.0){
            self.lat = locValue.latitude
            self.lng = locValue.longitude
            
            self.moveCamera(locValue.latitude, locValue.longitude)
            self.setMyLocation(self.lat, self.lng)
            self.myLocationImage.image = UIImage(named: "KnownLocation")
        }
        
        self.lat = locValue.latitude
        self.lng = locValue.longitude
    }
    
    func setMyLocation(_ lat: Double,_ long: Double){
        var position = CLLocationCoordinate2DMake(lat, long)
        var marker = GMSMarker(position: position)
        
        let circleCenter = CLLocationCoordinate2D(latitude: lat, longitude: long)
        
        var rad = 500.0

        
        let circle = GMSCircle(position: circleCenter, radius: rad)
        
        circle.fillColor = UIColor(red: 113, green: 204, blue: 231, alpha: 0.1)
        circle.strokeColor = .none
        
        circle.map = mapView
        
        marker.icon = UIImage(named: "MyLocationIcon")
        marker.isFlat = true
        marker.map = mapView
        
        self.myLocationMarker = marker
        self.myLocationCircle = circle
 
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    
    
    @IBAction func whenSetTapped(_ sender: Any) {
        self.showLoadingScreen()
        
        self.lat = mapView.camera.target.latitude
        self.lng = mapView.camera.target.longitude
        
        guard let filePath = Bundle.main.path(forResource: "maps-Info", ofType: "plist") else {
              fatalError("Couldn't find file 'maps-Info.plist'.")
            }
            // 2
            let plist = NSDictionary(contentsOfFile: filePath)
            guard let value = plist?.object(forKey: "GEO_API_KEY") as? String else {
              fatalError("Couldn't find key 'GEO_API_KEY' in 'maps-Info.plist'.")
            }
        
        var url: String = "https://maps.googleapis.com/maps/api/geocode/json?latlng=\(self.lat),\(self.lng)&key=\(value)"
        
        var request : NSMutableURLRequest = NSMutableURLRequest()
        request.url = NSURL(string: url) as URL?
        request.httpMethod = "GET"

        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue(), completionHandler:{ (response:URLResponse!, data: Data!, error: Error!) -> Void in
            var error: AutoreleasingUnsafeMutablePointer<NSError?>? = nil
            do{
                let jsonResult: NSDictionary! = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary

                if (jsonResult != nil) {
                    // process jsonResult

                    let results = jsonResult["results"] as! NSArray
                    let result_title = (results[0] as! NSDictionary)["formatted_address"] as! String
                    
                    print(result_title)
                    self.location_desc = result_title
                    
                    DispatchQueue.main.async {
                        self.hideLoadingScreen()
                        
                        self.skipButton.sendActions(for: .touchUpInside)
                    }
                    
                } else {
                   // couldn't load JSON, look at error
                }
            }catch {
            
            }


        })
    }
    
    @IBAction func whenCancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    var child = SpinnerViewController()
       var isShowingSpinner = false
       func showLoadingScreen() {
           if !isShowingSpinner {
               child = SpinnerViewController()
               // add the spinner view controller
               addChild(child)
               child.view.frame = view.frame
               view.addSubview(child.view)
               child.didMove(toParent: self)
               isShowingSpinner = true
           }
       }
       
       func hideLoadingScreen(){
           if isShowingSpinner {
               child.willMove(toParent: nil)
               child.view.removeFromSuperview()
               child.removeFromParent()
               isShowingSpinner = false
           }
       }
       
       
       
       struct reverseGeoData: Codable{
           var plus_code: PlusCode
           var results: [Result]
           var status: String
       }

       struct PlusCode: Codable{
           var compound_code: String
           var global_code: String
       }

       struct Result: Codable{
           var address_components: [AddressComponent]
           var formatted_address: String
           var geometry: Geometry
           var place_id: String
           var plus_code: PlusCodeX
           var types: [String]
       }

       struct AddressComponent: Codable{
           var long_name: String
           var short_name: String
           var types: [String]
       }

       struct Geometry: Codable{
           var location: Location
           var location_type: String
           var viewport: Viewport
       }

       struct Location: Codable{
           var lat: Double
           var lng: Double
       }

       struct Viewport: Codable{
           var northeast: Northeast
           var southwest: Southwest
       }

       struct Northeast: Codable{
           var lat: Double
           var lng: Double
       }

       struct Southwest: Codable{
           var lat: Double
           var lng: Double
       }

       struct PlusCodeX: Codable{
           var compound_code: String
           var global_code: String
       }
    
}
