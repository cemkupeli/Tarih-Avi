//
//  HelpViewController.swift
//  TarihAvi
//
//  Created by Cem Kupeli on 13.08.2020.
//  Copyright © 2020 Cem Kupeli. All rights reserved.
//

import UIKit

class HelpViewController: UIViewController {
    
    @IBOutlet weak var returnButton1: UIButton!
    @IBOutlet weak var returnButton2: UIButton!
    @IBOutlet weak var returnButton3: UIButton!
    
    
    override func viewDidLoad() {
        
        
        if returnButton1 != nil  {
            returnButton1.titleLabel?.adjustsFontSizeToFitWidth = true
        }
        else if returnButton2 != nil  {
            returnButton2.titleLabel?.adjustsFontSizeToFitWidth = true
        }
        else if returnButton3 != nil {
            returnButton3.titleLabel?.adjustsFontSizeToFitWidth = true
        }

        super.viewDidLoad()
    }
    
    override var prefersStatusBarHidden: Bool {
           return true
    }
    
    @IBAction func backPressed(_ sender: Any) {
    
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        self.dismiss(animated: true, completion: nil)
        
    }
    
}
