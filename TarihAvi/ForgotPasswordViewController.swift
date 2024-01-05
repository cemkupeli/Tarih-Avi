//
//  ForgotPasswordViewController.swift
//  TarihAvi
//
//  Created by Cem Kupeli on 1.07.2020.
//  Copyright © 2020 Cem Kupeli. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var resultText: UILabel!
    @IBOutlet weak var sendEmailButton: UIButton!
    @IBOutlet weak var returnButton: UIButton!
    
    let loadingView = UIView()
    
    override func viewDidLoad() {
        
        sendEmailButton.titleLabel?.adjustsFontSizeToFitWidth = true
        returnButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        resultText.isHidden = true
        emailText.text = ""
        
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func sendEmail(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        disableUserInteraction()
        addLoadingView()
        if emailText.text == "" {
            resultText.text = "Lütfen geçerli bir e-posta adresi girdiğinizden emin olun"
            loadingView.removeFromSuperview()
            enableUserInteraction()
        }
        else {
            Auth.auth().sendPasswordReset(withEmail: emailText.text!) { (error) in
                if error != nil  {
                    let errorCode = (error! as NSError).code
                    print("Error code: \(errorCode)")
                    switch errorCode {
                    case AuthErrorCode.userNotFound.rawValue:
                        print("User not found")
                        self.resultText.text = "Kullanıcı bulunamadı, lütfen doğru e-posta adresini girdiğinizden emin olun"
                        self.resultText.isHidden = false
                    case AuthErrorCode.networkError.rawValue:
                        print("Could not reach database, check Internet connection")
                        self.resultText.text = "Sunucuya ulaşılamadı, lütfen İnternet bağlantınızı kontrol edin"
                        self.resultText.isHidden = false
                    case AuthErrorCode.invalidEmail.rawValue:
                        print("User has entered an invalid email")
                        self.resultText.text = "Lütfen geçerli bir e-posta adresi girdiğinizden emin olun"
                        self.resultText.isHidden = false
                    default:
                        print(errorCode)
                        self.resultText.text = "E-posta yollanamadı, lütfen tekrar deneyin"
                        self.resultText.isHidden = false
                    }
                    self.emailText.text = ""
                    self.loadingView.removeFromSuperview()
                    self.enableUserInteraction()
                }
                else {
                    self.resultText.text = "Şifre yenileme e-postası yollandı"
                    self.resultText.isHidden = false
                    self.emailText.text = ""
                    self.loadingView.removeFromSuperview()
                    self.enableUserInteraction()
                }
            }
        }
        
    }
    
    func addLoadingView() {
        
        view.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        
        let viewWidth = view.frame.width
        loadingView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: viewWidth/2 - 90).isActive = true
        loadingView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(viewWidth/2 - 90)).isActive = true
        let viewHeight = view.frame.height
        loadingView.topAnchor.constraint(equalTo: view.topAnchor, constant: viewHeight/2 - 90).isActive = true
        loadingView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(viewHeight/2 - 90)).isActive = true
        
        
        loadingView.backgroundColor = UIColor.white
        
        let loadingLabel = UILabel()
        loadingView.addSubview(loadingLabel)

        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        
        loadingLabel.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor, constant: 15).isActive = true
        loadingLabel.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor, constant: -15).isActive = true
        loadingLabel.bottomAnchor.constraint(equalTo: loadingView.bottomAnchor).isActive = true
        loadingLabel.heightAnchor.constraint(equalTo: loadingView.heightAnchor, multiplier: 1/3).isActive = true
        
        loadingLabel.text = "Yükleniyor"
        loadingLabel.textAlignment = .center
        loadingLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        loadingLabel.adjustsFontSizeToFitWidth = true

        
        let loadingSign = UIActivityIndicatorView()
        loadingView.addSubview(loadingSign)
        
        loadingSign.translatesAutoresizingMaskIntoConstraints = false
        
        loadingSign.leadingAnchor.constraint(equalTo: loadingView.leadingAnchor, constant: 20).isActive = true
        loadingSign.trailingAnchor.constraint(equalTo: loadingView.trailingAnchor, constant: -20).isActive = true
        loadingSign.topAnchor.constraint(equalTo: loadingView.topAnchor, constant: 10).isActive = true
        loadingSign.heightAnchor.constraint(equalTo: loadingView.heightAnchor, multiplier: 2/3, constant: -10).isActive = true
        
        loadingSign.startAnimating()
        loadingSign.color = UIColor.darkGray
        loadingSign.transform = CGAffineTransform(scaleX: 2.5, y: 2.5)
        
    }
    
    @IBAction func returnPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func enableUserInteraction() {
        
        sendEmailButton.isUserInteractionEnabled = true
        returnButton.isUserInteractionEnabled = true
        
    }
    
    func disableUserInteraction() {
        
        sendEmailButton.isUserInteractionEnabled = false
        returnButton.isUserInteractionEnabled = false
        
    }
}
