//
//  AnimationViewController.swift
//  UberClone
//
//  Created by Rethink on 01/04/22.
//

import UIKit
import Lottie

var animationView: AnimationView?


class AnimationViewController: UIViewController {
   
    @IBAction func viewAnimeted(_ sender: Any) {
        animationView = .init(name: "car")
        
        animationView!.frame = view.bounds
        animationView!.contentMode = .scaleAspectFit
        animationView!.loopMode = .loop
        animationView!.animationSpeed = 0.5
        
        view.addSubview(animationView!)
        
        animationView!.play()
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

 
}
