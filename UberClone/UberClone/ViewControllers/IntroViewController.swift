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
                self.performSegue(withIdentifier: "introToMain", sender: nil)
            }else{
                let alert =  Alert(title: "Erro ai autenticar login", message: "Entre novamente!!!")
                self.present(alert.getAlert(), animated: true, completion: nil)
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
