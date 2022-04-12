//
//  AcceptRaceViewController.swift
//  UberClone
//
//  Created by Rethink on 06/04/22.
//

import UIKit
import CoreLocation
import MapKit
import FirebaseDatabase
import FirebaseAuth

enum StatusRun: String{
    case InRequest, OnBoard, BeginRun, InRun
}

class AcceptRaceViewController: UIViewController, CLLocationManagerDelegate{

    
    @IBOutlet weak var map: MKMapView!
    
    let driverViewController = DriverTableViewController()
    
    
    
    @IBOutlet weak var acceptedUberReference: UIButton!
    var namePassenger = ""
    var emailPassenger = ""
    var localPassenger = CLLocationCoordinate2D()
    var localDriver = CLLocationCoordinate2D()
    var localManager = CLLocationManager()
    var statusRun: StatusRun = .InRequest
 
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let coordinate = manager.location?.coordinate{
            
            self.localDriver = coordinate
            self.localDriverUpdate()
            
        }
    }
    
    func localDriverUpdate(){
        //update in firebase
        
        let database = Database.database().reference()
        
        if self.emailPassenger != ""{
            
            let request = database.child("request")
            let searchRequest = request.queryOrdered(byChild: "email").queryEqual(toValue: emailPassenger)
            
            searchRequest.observeSingleEvent(of: .childAdded) { (snapshot) in
                
                if let data = snapshot.value as? [String : Any]{
                    if let statusRecover = data["status"] as? String{
                        
                        // InRequest, OnBoard, BeginRun, InRun
                        
                        
                        //Status change
                        if statusRecover == StatusRun.OnBoard.rawValue{
                            
                            //verificar se o motorista está proximo
                            let driverLocation = CLLocation(latitude: self.localDriver.latitude, longitude: self.localDriver.longitude)
                            let passengerLotaion = CLLocation(latitude: self.localPassenger.latitude, longitude: self.localPassenger.longitude)
                            let distance = driverLocation.distance(from: passengerLotaion)
                            let distanceKM = distance/1000
                            
                            var newStatus = self.statusRun.rawValue
                            
                            if distanceKM <= 0.5{
                                newStatus = StatusRun.BeginRun.rawValue
                            }
                        
                            let dataDriver = [
                            
                                "driverLatitude" : self.localDriver.latitude,
                                "driverLongitude": self.localDriver.longitude,
                                "status": newStatus
                                
                            ] as [String : Any]
                            snapshot.ref.updateChildValues(dataDriver)
                            
                        }else if statusRecover == StatusRun.InRequest.rawValue{
                        
                        }else if statusRecover == StatusRun.InRun.rawValue{
                            
                        }else if statusRecover == StatusRun.BeginRun.rawValue{
                            self.swichButtonToInRun()
                        }
                    }
                }
            }
        }
        
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        
        //Config manager
        localManager.delegate = self
        localManager.desiredAccuracy = kCLLocationAccuracyBest
        localManager.requestWhenInUseAuthorization()
        localManager.startUpdatingLocation()
        localManager.allowsBackgroundLocationUpdates = true
        
        let region = MKCoordinateRegion.init(center: self.localPassenger, latitudinalMeters: 200, longitudinalMeters: 200)
        
        map.setRegion(region, animated: true)
        
        
     
        
        let note = MKPointAnnotation()
        note.coordinate = self.localPassenger
        note.title = self.namePassenger
        map.addAnnotation(note)
        
        
        
//usar pra colocar um carrinho na localizaçao do motorista
//        let noteView = MKAnnotationView(annotation: note, reuseIdentifier: nil)
//        noteView.image = UIImage.init(named: "uperCar")
    }
    
    
    @IBAction func acceptRun(_ sender: Any) {
            
        if self.statusRun == StatusRun.InRequest{
            
            // update request with driver coord
            let database = Database.database().reference()
            let auth = Auth.auth()
            let request = database.child("request")
            
            if let driverEmail = auth.currentUser?.email{
                request.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassenger).observeSingleEvent(of: .childAdded) { (snapshot) in
                    
                    let dataDriver = [
                        "driverEmail": driverEmail,
                        "driverLatitude": self.localDriver.latitude,
                        "driverLongitude": self.localDriver.longitude,
                        "status": StatusRun.OnBoard.rawValue
                    ] as [String : Any]
                    
                    snapshot.ref.updateChildValues(dataDriver)
                    self.onBoard()
                }
            }
            
            
            
            //mostrar o caminho
            let passengerCLL = CLLocation(latitude: localPassenger.latitude, longitude: localPassenger.longitude)
            
            CLGeocoder().reverseGeocodeLocation(passengerCLL) { (locais, erro) in
                if erro == nil{
                    if let dataLocal = locais?.first{
                        
                        let placeMark = MKPlacemark(placemark: dataLocal)
                        let mapItem = MKMapItem(placemark: placeMark)
                        mapItem.name = self.namePassenger
                        
                        let options = [MKLaunchOptionsDirectionsModeKey:  MKLaunchOptionsDirectionsModeDriving]
                        mapItem.openInMaps(launchOptions: options)
                    }
                }else{
                    print("erro boy")
                }
                
            }
        }
    }
    
    func onBoard(){
        //alterna status
        self.statusRun = StatusRun.OnBoard
        // alterba botao
        swichButtonToOnBoard()
    }
    
    func swichButtonToOnBoard(){
        self.acceptedUberReference.setTitle("A caminho do passageiro!", for: .normal)
        self.acceptedUberReference.backgroundColor = UIColor(red: 0.902, green: 0.906, blue: 0.906, alpha: 1)
        self.acceptedUberReference.isEnabled = false
    }
    func swichButtonToInRun(){
        self.acceptedUberReference.setTitle("Iniciar corrida!", for: .normal)
        self.acceptedUberReference.backgroundColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1)
        self.acceptedUberReference.isEnabled = true
    }

    
}
