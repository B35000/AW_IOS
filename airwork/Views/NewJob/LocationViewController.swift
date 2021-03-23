//
//  LocationViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 03/01/2021.
//

import UIKit
import GoogleMaps

class LocationViewController: UIViewController {
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
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
        mapView.settings.myLocationButton = true
        mapView.layer.cornerRadius = 15
        
        let locStatus = CLLocationManager.authorizationStatus()
                
        if locStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
            
            if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways) {
                var currentLoc: CLLocation? = locationManager.location
                print(currentLoc?.coordinate.latitude)
                print(currentLoc?.coordinate.longitude)
                
                if currentLoc?.coordinate.latitude != nil {
                    moveCamera(currentLoc!.coordinate.latitude, currentLoc!.coordinate.longitude)
                }
          }
        }else{
            if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways) {
                    var currentLoc: CLLocation? = locationManager.location
                    print(currentLoc?.coordinate.latitude)
                    print(currentLoc?.coordinate.longitude)
                
                    if currentLoc?.coordinate.latitude != nil {
                        moveCamera(currentLoc!.coordinate.latitude, currentLoc!.coordinate.longitude)
                    }
                
          }
        }
            
        
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .restricted, .denied:
                    print("No access to location enabled")
                case .authorizedAlways, .authorizedWhenInUse:
                    print("Access to location enabled")
                @unknown default:
                break
            }
            } else {
                print("Location services are not enabled")
        }
        
    }
    
    
    func moveCamera(_ lat: Double,_ long: Double){
        mapView.animate(to: GMSCameraPosition(latitude: lat, longitude: long, zoom: 15))
        
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
