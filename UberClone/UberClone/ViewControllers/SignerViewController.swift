//
//  SignerViewController.swift
//  UberClone
//
//  Created by Rethink on 01/04/22.
//

import UIKit
import Firebase

class SignerViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var typeOfRegister: UISwitch!
    
    @IBOutlet weak var registerButtumReference: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
      
    }
    
    func validateField() -> String{
        if (((self.emailTextField.text?.isEmpty) == nil)){
            return "E-mail"
        }else if((self.nameTextField.text?.isEmpty) == nil){
            return "Nome"
        }else if ((self.passwordTextField.text?.isEmpty) == nil){
            return "Senha"
        }
        return ""
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        
    }
    
    @IBAction func registerButtumAction(_ sender: Any) {
        
        let validateReturn = validateField()
        if validateReturn == ""{
            
            let auth = Auth.auth()
          
            
            if let email = self.emailTextField.text{
                if let name = self.nameTextField.text{
                    if let password = self.passwordTextField.text {
                        
                        auth.createUser(withEmail: email, password: password) { (user, erro) in
                            if erro == nil{
                                
                                //Validar login
                                if user != nil{
                                  
                                    //ver o tipo de usuario
                                    var type = ""
                                    if self.typeOfRegister.isOn{
                                        type = "Passageiro"
                                    }else{
                                        type = "Motorista"
                                    }
                                    
                                    //Cria um dicionario com os valores
                                    let usersArray = [
                                        "name": name,
                                        "email": email,
                                        "userType": type
                                    ] as [String : Any]
                                    
                                    //Salva no database
                                    let database = Database.database().reference()
                                    let users = database.child("Users")
                                    users.child((user?.user.uid)!).setValue(usersArray)
                                    
                                    
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
            }
            
            
            
            
            
            
        }else{
            let alert = Alert(title: "Dados incoerentes, preencha todos os campos!", message: "Por Favor confime os dados do campo \(validateReturn) e tente novamente!")
            self.present(alert.getAlert(), animated: true, completion: nil)
        }
    }
    

}
