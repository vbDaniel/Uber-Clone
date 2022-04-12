//
//  Main Main MainTravelerViewController.swift
//  UberClone
//
//  Created by Rethink on 04/04/22.
//

import UIKit
import Firebase
import MapKit

class MainTravelerViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate{
    
    @IBOutlet weak var callUberReference: UIButton!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var indicatorColorLocal: UIView!
    @IBOutlet weak var indicatorColorDestine: UIView!
    @IBOutlet weak var passangerLocal: UITextField!
    @IBOutlet weak var passengerDestine: UITextField!
    
    var localManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var driverLocation = CLLocationCoordinate2D()
    
    var ubercalled = false
    var uberAccept = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        localManager.delegate = self
        localManager.desiredAccuracy = kCLLocationAccuracyBest
        localManager.requestWhenInUseAuthorization()
        localManager.startUpdatingLocation()
        
        
        let database = Database.database().reference()
        let auth = Auth.auth()
        
    
        
        if let userEmail = auth.currentUser?.email{
            
            let request = database.child("request")
            
            //add observador se o usurioa pediu uma corrida e troca o botao para cancelar msm se o cara deslogar
            request.queryOrdered(byChild: "email").queryEqual(toValue: userEmail).observe(.childAdded) { (snapshot) in
                if snapshot.value != nil{
                    self.swichButtonToCancel()
                }
            }
            //add observador se quando o motorista aceita a corrida
            request.observe(.childChanged) { (snapshot) in
                if let data = snapshot.value as? [String : Any]{
                    if let latDriver = data["driverLatitude"]{
                        if let longDriver = data["driverLongitude"]{
                            print("TESTE")
                            self.driverLocation = CLLocationCoordinate2D(latitude: latDriver as! CLLocationDegrees, longitude: longDriver as! CLLocationDegrees)
                            self.showDriverAndPassenger()
                        }
                    }
                }
            }
            
        }
    }
    
    func showDriverAndPassenger(){
        //configura o uber como a caminho
        self.uberAccept = true
        
        //Calcular distancia entre driver e passenger
        let driverCLLocation = CLLocation(latitude: self.driverLocation.latitude, longitude: self.driverLocation.longitude)
        let passengerCLLocation = CLLocation(latitude: self.userLocation.latitude, longitude: self.userLocation.longitude)
        
        let distance = driverCLLocation.distance(from: passengerCLLocation) // em metros
        let distanceKM = distance/1000
        
        self.callUberReference.setTitle("Motorista a \(round(distanceKM)) KM de distância", for: .normal)
        self.callUberReference.backgroundColor = UIColor(red: 0.902, green: 0.906, blue: 0.906, alpha: 1)
        self.callUberReference.isEnabled = false
        
        //exibir uma note de ambos drive e passenger
        let allAnnotations = self.map.annotations
        self.map.removeAnnotations(allAnnotations)
        
        
        //fazer a diferença das latitudes e long para que assim apareça ambas o motorista e passageiro
        // abs() entrega sempre um valor possitivo
        //        let latDiference = (abs(self.userLocation.latitude) - abs(self.driverLocation.latitude)) * 3000
        //        let longDiference = (abs(self.userLocation.longitude) - abs(self.driverLocation.longitude)) * 3000
        //    print("\(latDiference) e  \(longDiference)  = \(longDiference * 3000)")
        
        
        //Aqui é onde vai ficar centralizado a tela do mapa
        let region = MKCoordinateRegion(center: self.userLocation, latitudinalMeters: 3000, longitudinalMeters: 3500)
        self.map.setRegion(region, animated: true)
        
        
        
        
        //coloca uma note pro passageiro e para o motorista de forma atualizado
        //DRIVER NOTE
        let driverNote = MKPointAnnotation()
        driverNote.coordinate = self.driverLocation
        driverNote.title = "Motorista"
        
        self.map.addAnnotation(driverNote)
        
        
        
        //PASSENGER NOTE
        let passengerNote = MKPointAnnotation()
        passengerNote.coordinate = self.userLocation
        passengerNote.title = "you"
        self.map.addAnnotation(passengerNote)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
        
        if let coordinate = manager.location?.coordinate{
            
            
            if self.ubercalled {
                showDriverAndPassenger()
            }else{
                self.userLocation = coordinate
                
                let region = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
                self.map.setRegion(region, animated: true)
                
                self.map.removeAnnotations(map.annotations)//remove notes anteriores
                
                let passengerNote = MKPointAnnotation()
                passengerNote.coordinate = coordinate
                passengerNote.title = "Seu local"
                
                //colocar um ponto diferente
                let noteView2 = MKAnnotationView(annotation: passengerNote, reuseIdentifier: nil)
                noteView2.image = UIImage.init(named: "pointer")
                self.map.addAnnotation(passengerNote)
            }
        }
    }
    
    @IBAction func signOut(_ sender: Any) {
        let auth = Auth.auth()
        
        do {
            try auth.signOut()
            dismiss(animated: true, completion: nil)//volta a tela inicial
        } catch {
            let alert = Alert(title: "Erro ao deslogar", message: "Tente Novamente!")
            self.present(alert.getAlert(), animated: true, completion: nil)
        }
        
    }
    
    @IBAction func callUber(_ sender: Any) {
        
        let database = Database.database().reference()
        let auth = Auth.auth()
        
        
        let request = database.child("request")
        
        if let userEmail = auth.currentUser?.email{
            if self.ubercalled{
                //uber chamado
                
                self.swichButtonToCall()
                
                //remover dados do pedido
                let request = database.child("request")
                request.queryOrdered(byChild: "email").queryEqual(toValue: userEmail).observeSingleEvent(of: .childAdded) { (snapshot) in
                    
                    snapshot.ref.removeValue()
                }
                
            }else{
                //uber nao chamado
                self.saveRequest()
            }
        }
    }
    
    
    func saveRequest(){
        
        let database = Database.database().reference()
        let auth = Auth.auth()
        
        
        let request = database.child("request")
        
        if let userEmail = auth.currentUser?.email{
            if let userId = auth.currentUser?.uid{
                
                if let finalAdress = self.passengerDestine.text{
                    if finalAdress != ""{
                        
                        
                        CLGeocoder().geocodeAddressString(finalAdress) { (local, erro) in
                            if erro == nil{
                                if let dataLocal = local?.first{
                                    
                                    var street = ""
                                    if dataLocal.thoroughfare != nil{
                                        street = dataLocal.thoroughfare!
                                    }
                                    var number = ""
                                    if dataLocal.subThoroughfare != nil{
                                        number = dataLocal.subThoroughfare!
                                    }
                                    var neighbor = ""
                                    if dataLocal.subLocality != nil{
                                        neighbor = dataLocal.subLocality!
                                    }
                                    var city = ""
                                    if dataLocal.locality != nil{
                                        city = dataLocal.locality!
                                    }
                                    var cep = ""
                                    if dataLocal.postalCode != nil{
                                        cep = dataLocal.postalCode!
                                    }
                                    let mainAdress = "\(street), \(number), \(neighbor) - \(city) \(cep)"
                                    
                                    
                                    if let latDestine = dataLocal.location?.coordinate.latitude{
                                        if let longDestine = dataLocal.location?.coordinate.longitude{
                                            
                                            let alertController = UIAlertController(title: "Confirme seu endereço!", message:  mainAdress, preferredStyle: .alert)
                                           
                                            let cancel = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
                                            let confirm = UIAlertAction(title: "Confirmar", style: .default, handler: { (alertAction) in
                                                
                                                let database = Database.database().reference()
                                                let user = database.child("Users").child(userId)


                                                user.observeSingleEvent(of: .value, with: { (snapshot) in
                                                    let data = snapshot.value as? NSDictionary
                                                    let userName = data!["name"] as? String

                                                    //troca o botao
                                                    self.swichButtonToCancel()

                                                    //salvar dados do pedido
                                                    let userData = [
                                                        "destineLat": latDestine,
                                                        "destineLong": longDestine,
                                                        "email": userEmail,
                                                        "name": userName,
                                                        "lat": self.userLocation.latitude,
                                                        "long": self.userLocation.longitude
                                                    ] as [String : Any]

                                                    request.childByAutoId().setValue(userData)
                                                })
                                                
                                            })
                                            alertController.addAction(cancel)
                                            alertController.addAction(confirm)
                                            self.present(alertController, animated: true, completion: nil)
                                        }
                                    }
                                }
                            }else{
                                print("Erro ao encontrar endereço")
                            }
                        }
                    }else{
                        print("Endereço nao encontrado!")
                    }
             
                
                

                }
            }
        }
    }
    
    func swichButtonToCall(){
        self.callUberReference.setTitle("Chamar Uber", for: .normal)
        self.callUberReference.backgroundColor = UIColor(red: 0.000, green: 0.000, blue: 0.000, alpha: 1)
        self.ubercalled = false
    }
    func swichButtonToCancel(){
        self.callUberReference.setTitle("Cancelar Uber", for: .normal)
        self.callUberReference.backgroundColor = UIColor(red: 1.000, green: 0.000, blue: 0.254, alpha: 1)
        self.ubercalled = true
    }
    
    

    
}
