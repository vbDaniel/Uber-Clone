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
                   
                    if let status = data["status"] as? String{
                        if status == StatusRun.pickUpPassenger.rawValue{
                            if let latDriver = data["driverLatitude"]{
                                if let longDriver = data["driverLongitude"]{
                                    
                                    self.driverLocation = CLLocationCoordinate2D(latitude: latDriver as! CLLocationDegrees, longitude: longDriver as! CLLocationDegrees)
                                    self.showDriverAndPassenger()
                                }
                            }
                        }else if (status == StatusRun.InRun.rawValue){
                            self.swichButtonToInRun()
                            self.userLocation = self.driverLocation
                        }else if (status == StatusRun.FinishedRun.rawValue){
                            if let price = data["runPrice"] as? Double{
                                self.swichButtonToFinished(price: price)
                            }
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
        
        var message = ""
        
        let distance = driverCLLocation.distance(from: passengerCLLocation) // em metros
        let distanceKM = distance/1000
        if distanceKM < 1{
            message = "Motorista a \(round(distance)) metros de distância"
        }else{
            message = "Motorista a \(round(distanceKM)) KM de distância"
        }
        
        self.callUberReference.setTitle(message, for: .normal)
        self.callUberReference.backgroundColor = UIColor(red: 0.902, green: 0.906, blue: 0.906, alpha: 1)
        self.callUberReference.isEnabled = false
        
        //exibir uma note de ambos drive e passenger
        let allAnnotations = self.map.annotations
        self.map.removeAnnotations(allAnnotations)
        
        
        //fazer a diferença das latitudes e long para que assim apareça ambas o motorista e passageiro
        //abs() entrega sempre um valor possitivo
        
        let latDiferenca = abs(self.userLocation.latitude - self.driverLocation.latitude) * 300000
        let lonDiferenca = abs(self.userLocation.longitude - self.driverLocation.longitude) * 300000
        
        //  let region = MKCoordinateRegion(center: launchLocal, latitudinalMeters: 2000, longitudinalMeters: 2000)
        let region = MKCoordinateRegion.init( center: self.userLocation, latitudinalMeters: latDiferenca, longitudinalMeters: lonDiferenca)
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
    ///
    ///aaa
    ///
    ///
    ///a
    ///
    ///
    ///aaaa
    ///
    ///aaa manoooo né possivel
    ///
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let noteView = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
        
        
        let noteLocation = annotation.coordinate
        if noteLocation.latitude == self.userLocation.latitude{
            if noteLocation.longitude == self.userLocation.longitude{
        
                noteView.image = UIImage(named: "points")
            
            }
        }else{
            noteView.image = UIImage(named: "upCar")
        }
        
           
        
        var frame = noteView.frame
        frame.size.height = 50
        frame.size.width = 50
        
        noteView.frame = frame
        
        
        return noteView
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
        
        if let coordinate = manager.location?.coordinate{
            
            self.userLocation = coordinate
            
            if self.ubercalled {
                showDriverAndPassenger()
            }else{
                let region = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
                self.map.setRegion(region, animated: true)
                
                self.map.removeAnnotations(map.annotations)//remove notes anteriores
                
                
                let passengerNote = MKPointAnnotation()
                passengerNote.coordinate = coordinate
                passengerNote.title = "Seu local"
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
    
    func swichButtonToInRun(){
        self.callUberReference.setTitle("Em viagem!", for: .normal)
        self.callUberReference.backgroundColor = UIColor(red: 0.902, green: 0.906, blue: 0.906, alpha: 1)
        self.callUberReference.isEnabled = false
    }
    
    func swichButtonToFinished(price: Double){
        self.callUberReference.backgroundColor = UIColor(red: 0.902, green: 0.906, blue: 0.906, alpha: 1)
        self.callUberReference.isEnabled = false
       
        
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
        self.callUberReference.setTitle("Viagem Finalizada - \(priceFormatter!) ", for: .normal)
    }
}
