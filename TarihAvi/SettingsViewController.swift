//
//  SettingsViewController.swift
//  TarihAvi
//
//  Created by Cem Kupeli on 8.04.2020.
//  Copyright © 2020 Cem Kupeli. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SettingsViewController: UIViewController {

    @IBOutlet weak var emailText: UITextView!
    @IBOutlet weak var usernameText: UITextView!
    @IBOutlet weak var soundEffectsButton: UIButton!
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var speakerIcon: UIImageView!
    
    override func viewDidLoad() {
        
        returnButton.titleLabel?.adjustsFontSizeToFitWidth = true
        soundEffectsButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        emailText.text = GlobalVariables.userEmail
        usernameText.text = GlobalVariables.userUsername
        
        if GlobalVariables.soundEffectsOn == true {
            speakerIcon.image = UIImage(named: "speaker")
        }
        else {
            speakerIcon.image = UIImage(named: "muted")
        }
        
        super.viewDidLoad()
    }
    
    @IBAction func soundEffectsPressed(_ sender: Any) {

        if GlobalVariables.soundEffectsOn == true {
            
            soundEffectsButton.setTitle("Ses efektleri kapalı", for: .normal)
            speakerIcon.image = UIImage(named: "muted")
            GlobalVariables.soundEffectsOn = false
           
        }
        else if GlobalVariables.soundEffectsOn == false {
            
            GlobalVariables.soundEffect.play()
            soundEffectsButton.setTitle("Ses efektleri açık", for: .normal)
            speakerIcon.image = UIImage(named: "speaker")
            GlobalVariables.soundEffectsOn = true

        }
        
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        self.dismiss(animated: true, completion: nil)
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

}
