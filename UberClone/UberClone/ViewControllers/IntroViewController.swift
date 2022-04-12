//
//  IntroViewController.swift
//  UberClone
//
//  Created by Rethink on 31/03/22.
//

import UIKit
import Lottie
import Firebase

class IntroViewController: UIViewController {
    @IBOutlet weak var registerReference: UIButton!
    @IBOutlet weak var loginReference: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        let auth = Auth.auth()
    
        
        auth.addStateDidChangeListener { (auth, user) in
            if user != nil{
                
                let database = Database.database().reference()
                let userID = database.child("Users").child(user!.uid)
                userID.observeSingleEvent(of: .value) { (snapshot) in
                    let data = snapshot.value as? NSDictionary
                    if data != nil{
                        let userType = data?["userType"] as? String
                        if userType == "Passageiro"{
                            self.performSegue(withIdentifier: "introToMain", sender: nil)
                        }else{
                            self.performSegue(withIdentifier: "introToMainAsDriver", sender: nil)
                        }
                    }else{
                        print("Erro ao buscar cadastro!!!")
                    }
                    
                }
                
            }else{
                print("Algum erro ao logar ou o usuario deu signOut")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.navigationController?.setNavigationBarHidden(true, animated: false)
        
    }
    

    @IBAction func loginButton(_ sender: Any) {
        
    }
    
    @IBAction func register(_ sender: Any) {
        
    }
    
}
