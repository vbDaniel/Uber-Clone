//
//  Alert.swift
//  UberClone
//
//  Created by Rethink on 01/04/22.
//

import UIKit

class Alert{
    
    var title: String
    var message : String
    
    init(title: String, message: String){
        self.title = title
        self.message = message
    }
    
    func getAlert() -> UIAlertController{
        let alertController = UIAlertController(title: title, message:  message, preferredStyle: .alert)
       
        let cancel = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        alertController.addAction(cancel)
        
        return alertController
    }
}
