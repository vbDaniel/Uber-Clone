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



class AcceptRaceViewController: UIViewController, CLLocationManagerDelegate{
    
    
    @IBOutlet weak var map: MKMapView!
    
    let driverViewController = DriverTableViewController()
    
    
    
    @IBOutlet weak var acceptedUberReference: UIButton!
    var namePassenger = ""
    var emailPassenger = ""
    var localPassenger = CLLocationCoordinate2D()
    var localDriver = CLLocationCoordinate2D()
    var localManager = CLLocationManager()
    var localDestine = CLLocationCoordinate2D()
    var statusRun: StatusRun = .InRequest
    
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
        
        let database = Database.database().reference()
        let request = database.child("request")
        let searchRequest = request.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassenger)
        
        searchRequest.observe(.childChanged) { (snapshot) in
            if let data = snapshot.value as? [String : Any]{
                if let statusRecover = data["status"] as? String{
                    self.reloadViewStatus(status: statusRecover, data: data)
                }
            }
        }
        let price = database.child("price")
        price.child("KM").setValue(4)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let database = Database.database().reference()
        let request = database.child("request")
        let searchRequest = request.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassenger)
        
        searchRequest.observeSingleEvent(of: .childAdded) { (snapshot) in
            if let data = snapshot.value as? [String : Any]{
                if let statusRecover = data["status"] as? String{
                    self.reloadViewStatus(status: statusRecover, data: data)
                }
            }
        }
    }
    
    func reloadViewStatus(status: String, data: [String : Any]){

        if status == StatusRun.pickUpPassenger.rawValue{
            print("Status Pegar passageiro")
            self.pickUpPassenger()
            self.showDriverPassenger(launchLocal: self.localDriver, launchText: "Partida", destineLocal: self.localPassenger, destineText: "Chegada")
            
        }else if (status == StatusRun.BeginRun.rawValue){
            print("Status Começar corrida")
            
            self.statusRun = .BeginRun
            self.swichButtonToBeginRun()
           
            
            //recover destine local
            if let destineLat = data["destineLat"] as? Double{
                if let destineLong = data["destineLong"] as? Double{
                    self.localDestine = CLLocationCoordinate2D(latitude: destineLat, longitude: destineLong)
                }
            }
            
            self.showDriverPassenger(launchLocal: self.localDriver, launchText: "Motorista", destineLocal: self.localPassenger, destineText: "Passageiro")
        }else if (status == StatusRun.InRun.rawValue){
            //trocar status
            self.statusRun = .InRun
            
            //Switch Buttuon
            self.swichButtonToFinishedRun()
            
            //recover destine local
            if let destineLat = data["destineLat"] as? Double{
                if let destineLong = data["destineLong"] as? Double{
                    self.localDestine = CLLocationCoordinate2D(latitude: destineLat, longitude: destineLong)
                    self.showDriverPassenger(launchLocal: self.localDriver, launchText: "Motorista", destineLocal: self.localDestine, destineText: "Destino")
                }
            }
            
        }else if (status == StatusRun.FinishedRun.rawValue){
            self.statusRun = .FinishedRun
            if let price = data["runPrice"]  as? Double{
                self.swichButtonToFinished(price: price)
            }
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let coordinate = manager.location?.coordinate{
            
            self.localDriver = coordinate
            self.localDriverUpdate()
            
        }
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
                        "status": StatusRun.pickUpPassenger.rawValue
                    ] as [String : Any]
                    
                    snapshot.ref.updateChildValues(dataDriver)
                    self.pickUpPassenger()
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
        }else if (self.statusRun == StatusRun.BeginRun){
            self.beginDestineTravel()
        }else if (self.statusRun == StatusRun.InRun){
            self.finishedRun()
        }
    }
    
    
    func beginDestineTravel(){
        
        //updata status
        self.statusRun = .InRun
        
        //uodate request in firebase
        self.updataStatusRequest(status: self.statusRun.rawValue)
        
        //exibir caminho no mapa
        let destineCLL = CLLocation(latitude: localDestine.latitude, longitude: localDestine.longitude)
        
        CLGeocoder().reverseGeocodeLocation(destineCLL) { (locais, erro) in
            if erro == nil{
                if let dataLocal = locais?.first{
                    
                    let placeMark = MKPlacemark(placemark: dataLocal)
                    let mapItem = MKMapItem(placemark: placeMark)
                    mapItem.name = "Destino Passageiro"
                    
                    let options = [MKLaunchOptionsDirectionsModeKey:  MKLaunchOptionsDirectionsModeDriving]
                    mapItem.openInMaps(launchOptions: options)
                }
            }else{
                print("erro boy")
            }
            
        }
    }
    
    func finishedRun(){
        //altera status
        self.statusRun = .FinishedRun
        
        //Dar um valor pro price/km
        let price: Double = 4
        
        let database = Database.database().reference()
        let request = database.child("request")
        let searchRequest = request.queryOrdered(byChild: "email").queryEqual(toValue: self.emailPassenger)
        
        searchRequest.observeSingleEvent(of: .childAdded) { (snapshot) in
            if let data = snapshot.value as? [String : Any]{
                if let beginLat = data["lat"] as? Double{
                    if let beginLong = data["long"] as? Double{
                        if let finalLat = data["destineLat"] as? Double{
                            if let finalLong = data["destineLong"] as? Double{
                                
                                let beginLocal = CLLocation(latitude: beginLat, longitude: beginLong)
                                let finalLocal = CLLocation(latitude: finalLat, longitude: finalLong)
                                
                                let distanceM = beginLocal.distance(from: finalLocal)
                                let distanceKM = distanceM/1000
                                let priceInKM = distanceKM * price
                                
                                let dataUpdate = [
                                    "runPrice": priceInKM,
                                    "distanceRun": distanceKM
                                ]
                                
                                snapshot.ref.updateChildValues(dataUpdate)
                                
                                //Atualiza no fire base
                                self.updataStatusRequest(status: self.statusRun.rawValue)
                                
                                //troca pra viajem finalizada
                                self.swichButtonToFinished(price: priceInKM)

                            }
                        }
                    }
                }
            }
        }
    }
    func localDriverUpdate(){
        //update in firebase
        
        let database = Database.database().reference()
        
        if self.emailPassenger != ""{
            
            let request = database.child("request")
            let searchRequest = request.queryOrdered(byChild: "email").queryEqual(toValue: emailPassenger)
            
            searchRequest.observeSingleEvent(of: .childAdded) { [self] (snapshot) in
                
                if let data = snapshot.value as? [String : Any]{
                    if let statusRecover = data["status"] as? String{
                        
                        // InRequest, OnBoard, BeginRun, InRun
                        
                        
                        //Status change
                        if statusRecover == StatusRun.pickUpPassenger.rawValue{
                            
                            //verificar se o motorista está proximo
                            let driverLocation = CLLocation(latitude: self.localDriver.latitude, longitude: self.localDriver.longitude)
                            let passengerLocation = CLLocation(latitude: self.localPassenger.latitude, longitude: self.localPassenger.longitude)
                            let distance = driverLocation.distance(from: passengerLocation)
                            let distanceKM = distance/1000
                            
                            
                            
                            if distanceKM <= 0.5{
                                self.updataStatusRequest(status: StatusRun.BeginRun.rawValue)
                            }
                            

                            
                        }else if (statusRecover == StatusRun.BeginRun.rawValue){
                            
                            self.showDriverPassenger(launchLocal: self.localDriver, launchText: "Motorista", destineLocal: self.localPassenger, destineText: "Passageiro")
                        
//                            self.swichButtonToInRun()
//
//
                        }else if (statusRecover == StatusRun.InRun.rawValue){
                            if let destineLatitude = data["destineLat"] as? Double{
                               if let destineLongitude = data["destineLong"] as? Double{

                                   self.localDestine = CLLocationCoordinate2D(latitude: destineLatitude, longitude: destineLongitude)

                                   self.showDriverPassenger(launchLocal: self.localDriver, launchText: "Partida", destineLocal: self.localDestine, destineText: "Destino")
                               }
                            }
                        }
                        
                        let dataDriver = [

                            "driverLatitude" : self.localDriver.latitude,
                            "driverLongitude": self.localDriver.longitude,

                        ] as [String : Any]
                        snapshot.ref.updateChildValues(dataDriver)

                    }
                }
            }
        }
    }
    
    func updataStatusRequest(status: String){
        if status != "" && self.emailPassenger != ""{
            
            let database = Database.database().reference()
            let request = database.child("request")
            let searchRequest = request.queryOrdered(byChild: "email").queryEqual(toValue: emailPassenger)
            
            
            searchRequest.observeSingleEvent(of: .childAdded) { (snapshot) in
                if let data = snapshot.value as? [String : Any]{
                    let dataUpdate = [
                        "status": status
                    ]
        
                    snapshot.ref.updateChildValues(dataUpdate)
                }
            }
        }
    }
    
    
    //Alterna botao para pegar passageiro
    
    func showDriverPassenger(launchLocal: CLLocationCoordinate2D, launchText: String, destineLocal: CLLocationCoordinate2D, destineText: String){
        
        let allAnnotations = self.map.annotations
        self.map.removeAnnotations(allAnnotations)
        
        //Aqui é onde vai ficar centralizado a tela do mapa
        
        let latDiferenca = abs(launchLocal.latitude - destineLocal.latitude) * 300000
        let lonDiferenca = abs(launchLocal.longitude - destineLocal.longitude) * 300000
        
        //  let region = MKCoordinateRegion(center: launchLocal, latitudinalMeters: 2000, longitudinalMeters: 2000)
        let region = MKCoordinateRegion.init( center: launchLocal, latitudinalMeters: latDiferenca, longitudinalMeters: lonDiferenca)
        self.map.setRegion(region, animated: true)
        
    
        //coloca uma note pro passageiro e para o motorista de forma atualizado
        //DRIVER NOTE
        let launch = MKPointAnnotation()
        launch.coordinate = launchLocal
        launch.title = launchText
        self.map.addAnnotation(launch)
        
        
        
        //PASSENGER NOTE
        let destine = MKPointAnnotation()
        destine.coordinate = destineLocal
        destine.title = destineText
        self.map.addAnnotation(destine)
        
        
    }
  
    //Pegar passageiro
    func pickUpPassenger () {
        //Alterar Status
        self.statusRun = StatusRun.pickUpPassenger
        //Alternar Botao
        self.swichButtonToPickUpPassenger()
    }
    
    func swichButtonToPickUpPassenger(){
        self.acceptedUberReference.setTitle("A caminho do passageiro!", for: .normal)
        self.acceptedUberReference.backgroundColor = UIColor(red: 0.902, green: 0.906, blue: 0.906, alpha: 1)
        self.acceptedUberReference.isEnabled = false
    }
    func swichButtonToBeginRun(){
        self.acceptedUberReference.setTitle("Iniciar corrida!", for: .normal)
        self.acceptedUberReference.backgroundColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1)
        self.acceptedUberReference.isEnabled = true
    }
    func swichButtonToFinishedRun(){
        self.acceptedUberReference.setTitle("Finalizar", for: .normal)
        self.acceptedUberReference.backgroundColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1)
        self.acceptedUberReference.isEnabled = true
    }
    
    func swichButtonToFinished(price: Double){
        self.acceptedUberReference.isEnabled = false
        self.acceptedUberReference.backgroundColor = UIColor(red: 0.902, green: 0.906, blue: 0.906, alpha: 1)
        
        //
        //Formataçao de NUMBERO PRA PREço
        //
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.locale = Locale(identifier: "pt_BR")
        //
        let priceFormatter = numberFormatter.string(from: NSNumber(value: price))
        
        //
        self.acceptedUberReference.setTitle("Viagem Finalizada - R$ \(priceFormatter!)", for: .normal)
    }
}
