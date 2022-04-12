//
//  LocalViewController.swift
//  UberClone
//
//  Created by Rethink on 06/04/22.
//

import UIKit
import FirebaseAuth

class LocalViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func actionSigOutButton(_ sender: Any) {
        let auth = Auth.auth()
        
        do {
            try auth.signOut()
            dismiss(animated: true, completion: nil)//volta a tela inicial
        } catch {
            let alert = Alert(title: "Erro ao deslogar", message: "Tente Novamente!")
            self.present(alert.getAlert(), animated: true, completion: nil)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
