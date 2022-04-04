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
    var localManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    
    var ubercalled = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        localManager.delegate = self
        localManager.desiredAccuracy = kCLLocationAccuracyBest
        localManager.requestWhenInUseAuthorization()
        localManager.startUpdatingLocation()
        
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
        if let coordinate = manager.location?.coordinate{
            
            self.userLocation = coordinate
            
            let region = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
            map.setRegion(region, animated: true)
            
            map.removeAnnotations(map.annotations)//remove notes anteriores
            
           
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
                request.queryOrdered(byChild: "email").queryEqual(toValue: userEmail).observeSingleEvent(of: DataEventType.value) { (snapshot) in
                    print(snapshot)
                }
                  
            }else{
                //uber nao chamado
                
                self.swichButtonToCancel()
                
                //salvar dados do pedido
                let userData = [
                    "email": userEmail,
                    "name": "",
                    "lat": self.userLocation.latitude,
                    "long": self.userLocation.longitude
                ] as [String : Any]

                request.childByAutoId().setValue(userData)
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
