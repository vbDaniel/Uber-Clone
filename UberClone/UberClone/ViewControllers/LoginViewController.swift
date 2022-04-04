//
//  LoginViewController.swift
//  UberClone
//
//  Created by Rethink on 01/04/22.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var typeLogin: UISwitch!
    
    @IBOutlet weak var loginButtomReference: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

       
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

    override func viewWillAppear(_ animated: Bool) {
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
    }
    @IBAction func loginButtomAction(_ sender: Any) {
        
        let validateReturn = validateField()
        if validateReturn == ""{
            
            let auth = Auth.auth()
            
            if let email = self.emailTextField.text{
                if let password = self.passwordTextField.text {
                    
                    auth.signIn(withEmail: email, password: password) { (user, erro) in
                        if erro == nil{
                            print("Sucessoooo!!! ao  logar user!!!")
                            if user != nil{
                                self.performSegue(withIdentifier: "loginToMain", sender: nil)
                                
                            }else{
                                let alert =  Alert(title: "Erro ai autenticar usuário", message: "Confira os dados e tente novamente!")
                                self.present(alert.getAlert(), animated: true, completion: nil)
                            }
                            
                            
                            
                            
                        }else{
                            let alert =  Alert(title: "Erro ai validadar dados", message: "Confira os dados e tente novamente!")
                            self.present(alert.getAlert(), animated: true, completion: nil)
                        }
                    }
                    
                }
            }
            
            
            
            
            
            
        }else{
            let alert = Alert(title: "Dados incoerentes, preencha todos os campos!", message: "Por Favor confime os dados do campo \(validateReturn) e tente novamente!")
            self.present(alert.getAlert(), animated: true, completion: nil)
        }

        
    
    }
    
    
    func validateField() -> String{
        if (((self.emailTextField.text?.isEmpty) == nil)){
            return "E-mail"
        }else if ((self.passwordTextField.text?.isEmpty) == nil){
            return "Senha"
        }
        return ""
    }
}
