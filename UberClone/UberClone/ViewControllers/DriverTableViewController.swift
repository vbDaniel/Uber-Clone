//
//  DriverTableViewController.swift
//  UberClone
//
//  Created by Rethink on 04/04/22.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import MapKit

class DriverTableViewController: UITableViewController, CLLocationManagerDelegate{
    var requestList: [DataSnapshot] = []
    var localManager = CLLocationManager()
    var driverLocation = CLLocationCoordinate2D()
    var timerManager = Timer()
    override func viewDidAppear(_ animated: Bool) {
        self.recoverData()
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { (timer) in
            self.recoverData()
            self.timerManager = timer
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.timerManager.invalidate()
    }
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
       
        
        //Config manager
        localManager.delegate = self
        localManager.desiredAccuracy = kCLLocationAccuracyBest
        localManager.requestWhenInUseAuthorization()
        localManager.startUpdatingLocation()
        
        
        let database = Database.database().reference()
        let request = database.child("request")
        
        self.requestList = []
        
        self.recoverData()
        
        //recuperar se alguma pedido foi cancelado e nao deixa o motorista aceitar
        request.observe(.childRemoved) { (snapshot) in
            var indice = 0
            for reqF in self.requestList {
                //snapshot.kye retorna o identificador do snap ai é comparado e excluido do array
                if reqF.key == snapshot.key{
                    self.requestList.remove(at: indice)
                }
                indice += 1
                
            }
            self.tableView.reloadData()
        }
    }
    
    func recoverData(){
        
        let database = Database.database().reference()
        let request = database.child("request")
        
        self.requestList = []
        
        //requecupera pedidos uma vez
        request.observeSingleEvent(of: .childAdded) { (snapshot) in
            self.requestList.append(snapshot)
            self.tableView.reloadData()
        }
    }


    // MARK: - Table view data source

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = manager.location?.coordinate{
            self.driverLocation = coordinate
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return requestList.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        let snapshot = self.requestList[indexPath.row]
        
        if let data = snapshot.value as? [String: Any]{
            
            if let latTravel = data["lat"]{
                if let longTravel = data["long"]{
                    
                    let driverLocal = CLLocation(latitude: self.driverLocation.latitude, longitude: self.driverLocation.longitude)
                    
                    let travelLocal = CLLocation(latitude: latTravel as! CLLocationDegrees, longitude: longTravel as! CLLocationDegrees)
                    
                    let distanceM = driverLocal.distance(from: travelLocal)
                    let distanceKM = round(distanceM/1000)
                
                    
                    var driverRequest = ""
                    
                    if let recoverDriverEmail = data["driverEmail"] as? String{
                        let auth = Auth.auth()
                        if let userEmail = auth.currentUser?.email{
                            if recoverDriverEmail == userEmail{
                                driverRequest = "EM ANDAMENTO"
                            }
                        }
                    }
                        
                    if let passengerName = data["name"] as? String{
                        cell.textLabel?.text = "\(passengerName) | \(driverRequest)"
                        cell.detailTextLabel?.text = "\(distanceKM) km de distância"
                    }
                    
                    
                }
            }
           
            
            
        }
               
        
        return cell
    }

    // performa a segue e envia para a class AcceptRaceViewCOntroller os dados de snapshot
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.tableView.reloadData()
        let snapshot = self.requestList[indexPath.row]
        self.performSegue(withIdentifier: "acceptRaceSegue", sender: snapshot)
    }
  
    
    @IBAction func refreshData(_ sender: Any) {
        self.tableView.reloadData()
    }
 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "acceptRaceSegue"{
            if let acceptViewController = segue.destination as? AcceptRaceViewController{
                
                let snapshot = sender as! DataSnapshot
                
                let data = snapshot.value as? NSDictionary
                
                
                acceptViewController.emailPassenger = data!["email"] as! String
                acceptViewController.namePassenger = data!["name"] as! String
                acceptViewController.localPassenger = CLLocationCoordinate2D(latitude: data!["lat"] as! CLLocationDegrees, longitude: data!["long"] as! CLLocationDegrees)
                acceptViewController.localDriver = self.driverLocation
       
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
    
   
}
