//
//  LoginViewController.swift
//  TarihAvi
//
//  Created by Cem Kupeli on 7.04.2020.
//  Copyright © 2020 Cem Kupeli. All rights reserved.
//


import UIKit
import Firebase
import FirebaseAuth
import AVFoundation

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var passwordText: UITextField!
    @IBOutlet weak var errorText: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var forgotPasswordButton: UIButton!
    @IBOutlet weak var rememberSwitch: UISwitch!
    
    // The UserDefaults interface
    let defaults = UserDefaults.standard
    
    // This boolean will be set to true once the categories are received, making sure that the getAwards method is called only once (the first conditional in the didSet is only fired once)
    var beganReceivingAwards = false

    var checks = ["categoriesReceived": false, "awardsReceived": false] {
        didSet {
            // In order to be able to add award data to a newly registered user, the current awards must be received at the login screen, but the getAwards function has to be called after the current categories are received since it makes use of the categories array to receive the award colors from the database
            if checks["categoriesReceived"] == true && beganReceivingAwards == false {
                beganReceivingAwards = true
                SetAssigner.getAwards(target: self)
            }
            if checks == ["categoriesReceived": true, "awardsReceived": true] {
                print("All checks completed, checks: \(checks)")
                loadingView.removeFromSuperview()
                enableUserInteraction()
                
                // Checks to see if the user is remembered, logs into their account if so
                rememberUser()
            }
        }
    }
    // The SetAssigner methods set this boolean to true if they encounter an error while accessing the database
    var encounteredError = false {
        didSet {
            if encounteredError == true {
                loadingView.removeFromSuperview()
                addErrorView()
                disableUserInteraction()
                encounteredError = false
            }
        }
    }
    
    let loadingView = UIView()
    let errorView = UIView()
    
    override func viewDidLoad() {
        
        loginButton.titleLabel?.adjustsFontSizeToFitWidth = true
        signupButton.titleLabel?.adjustsFontSizeToFitWidth = true
        forgotPasswordButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        if defaults.bool(forKey: "rememberUser") == true {
            print("Remembered user.")
        }
        else {
            print("Didn't remember user.")
        }
        
        errorText.isHidden = true
        disableUserInteraction()
        addLoadingView()
        // In order to be able to add new set data to a newly registered user, categories must be pulled at the login screen
        SetAssigner.getCategories(target: self)
        
        // Assign the sound file to the audio player
        do {
            try GlobalVariables.soundEffect = AVAudioPlayer(contentsOf: URL(fileURLWithPath: GlobalVariables.soundFile!))
        }
        catch {
            print(error)
        }
        
        // Sets the email text field's keyboard type
        emailText.keyboardType = .emailAddress

        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)
        
        
    }
    
    @IBAction func loginPressed(_ sender: Any) {
    
        errorText.isHidden = true
        disableUserInteraction()
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        
        if emailText.text == "" || passwordText.text == "" {
            print("At least one of the login fields is empty")
            errorText.text = "Lütfen boş alanları doldurun"
            errorText.isHidden = false
            enableUserInteraction()
        }
        else {
            addLoadingView()
            let email = emailText.text!
            let password = passwordText.text!
            
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                if error != nil  {
                    let errorCode = (error! as NSError).code
                    print("Error code: \(errorCode)")
                    switch errorCode {
                    case AuthErrorCode.userNotFound.rawValue:
                        print("User not found")
                        self.errorText.text = "Kullanıcı bulunamadı, lütfen doğru bilgileri girdiğinizden emin olun"
                        self.errorText.isHidden = false
                    case AuthErrorCode.networkError.rawValue:
                        print("Could not reach database, check Internet connection")
                        self.errorText.text = "Sunucuya ulaşılamadı, lütfen İnternet bağlantınızı kontrol edin"
                        self.errorText.isHidden = false
                    case AuthErrorCode.wrongPassword.rawValue:
                        print("User has entered the wrong password")
                        self.errorText.text = "Şifre yanlış, lütfen girdiğiniz şifreyi kontrol edin"
                        self.errorText.isHidden = false
                    case AuthErrorCode.invalidEmail.rawValue:
                        print("User has entered an invalid email")
                        self.errorText.text = "Lütfen geçerli bir e-posta adresi girdiğinizden emin olun"
                        self.errorText.isHidden = false
                    default:
                        print(errorCode)
                        self.errorText.text = "Giriş yapılamadı, lütfen tekrar deneyin"
                        self.errorText.isHidden = false
                    }
                    
                    // Deletes the password field's text
                    self.passwordText.text = ""
                    
                    self.loadingView.removeFromSuperview()
                    self.enableUserInteraction()
                }
                else {
                    print("Login successful")
                    
                    // Remembers user if the user has switched the "remember me" switch on
                    if self.rememberSwitch.isOn {
                        print("Remembering user")
                        self.defaults.set(true, forKey: "rememberUser")
                        self.defaults.set(self.emailText.text!, forKey: "email")
                        self.defaults.set(self.passwordText.text!, forKey: "password")
                    }
                    // Else, resets the remember settings
                    else {
                        self.defaults.set(false, forKey: "rememberUser")
                        self.defaults.set("", forKey: "email")
                        self.defaults.set("", forKey: "password")
                    }
                    
                    // Clears the text fields
                    self.emailText.text = ""
                    self.passwordText.text = ""
                    
                    self.loadingView.removeFromSuperview()
                    self.enableUserInteraction()
                    self.performSegue(withIdentifier: "homeSegue", sender: self)
                }
            }
        }
        
       
    }
    
    @IBAction func signupPressed(_ sender: Any) {
        
        errorText.isHidden = true
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        
        performSegue(withIdentifier: "signupSegue", sender: self)
        
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
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
    
    func addErrorView() {
        
        view.addSubview(errorView)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        
        let viewWidth = view.frame.width
        errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: viewWidth/2 - 110).isActive = true
        errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(viewWidth/2 - 110)).isActive = true
        let viewHeight = view.frame.height
        errorView.topAnchor.constraint(equalTo: view.topAnchor, constant: viewHeight/2 - 110).isActive = true
        errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -(viewHeight/2 - 110)).isActive = true
        
        errorView.backgroundColor = UIColor(named: "3")
        
        let errorLabel = UILabel()
        errorView.addSubview(errorLabel)
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        errorLabel.leadingAnchor.constraint(equalTo: errorView.leadingAnchor, constant: 10).isActive = true
        errorLabel.trailingAnchor.constraint(equalTo: errorView.trailingAnchor, constant: -10).isActive = true
        errorLabel.topAnchor.constraint(equalTo: errorView.topAnchor, constant: 10).isActive = true
        errorLabel.heightAnchor.constraint(equalTo: errorView.heightAnchor, multiplier: 0.7, constant: -10).isActive = true
        
        errorLabel.numberOfLines = 5
        errorLabel.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        errorLabel.adjustsFontSizeToFitWidth = true
        errorLabel.textColor = .black
        errorLabel.text = "Sunucuya bağlanılamıyor, lütfen internet bağlantınızı kontrol edip tekrar deneyin."
        errorLabel.textAlignment = .center
        
        let retryButton = UIButton()
        errorView.addSubview(retryButton)
        retryButton.translatesAutoresizingMaskIntoConstraints = false
        
        retryButton.centerXAnchor.constraint(equalTo: errorView.centerXAnchor).isActive = true
        retryButton.widthAnchor.constraint(equalTo: errorView.widthAnchor, multiplier: 0.5).isActive = true
        retryButton.heightAnchor.constraint(equalTo: errorView.heightAnchor, multiplier: 0.3).isActive = true
        retryButton.bottomAnchor.constraint(equalTo: errorView.bottomAnchor).isActive = true
        
        retryButton.setTitle("Tekrar dene", for: .normal)
        retryButton.titleLabel?.textAlignment = .center
        retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        retryButton.setTitleColor(.systemBlue, for: .normal)
        retryButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        retryButton.addTarget(self, action: #selector(retryButtonPressed), for: .touchUpInside)
        
    }
    
    @IBAction func retryButtonPressed() {
        // Resets all checks and restarts the sequence of functions that retrieve/update necessary information
        print("Recalling database methods")
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        disableUserInteraction()
        errorView.removeFromSuperview()
        addLoadingView()
        beganReceivingAwards = false
        checks = ["categoriesReceived": false, "awardsReceived": false]
        SetAssigner.getCategories(target: self)
    }
    
    @IBAction func forgotPasswordPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        performSegue(withIdentifier: "forgotPasswordSegue", sender: self)
        
    }
    
    func enableUserInteraction() {
        
        emailText.isUserInteractionEnabled = true
        passwordText.isUserInteractionEnabled = true
        errorText.isUserInteractionEnabled = true
        loginButton.isUserInteractionEnabled = true
        signupButton.isUserInteractionEnabled = true
        forgotPasswordButton.isUserInteractionEnabled = true
        
    }
    
    func disableUserInteraction() {
        
        emailText.isUserInteractionEnabled = false
        passwordText.isUserInteractionEnabled = false
        errorText.isUserInteractionEnabled = false
        loginButton.isUserInteractionEnabled = false
        signupButton.isUserInteractionEnabled = false
        forgotPasswordButton.isUserInteractionEnabled = false
        
    }
    
    func rememberUser() {
        
        if defaults.bool(forKey: "rememberUser") == true {
            
            disableUserInteraction()
            addLoadingView()
            
            let email = defaults.string(forKey: "email")
            let password = defaults.string(forKey: "password")
            
            Auth.auth().signIn(withEmail: email!, password: password!) { (user, error) in
                if error != nil  {
                    let errorCode = (error! as NSError).code
                    print("Error code: \(errorCode)")
                    switch errorCode {
                    case AuthErrorCode.userNotFound.rawValue:
                        print("Saved user not found")
                        self.errorText.text = "Kayıtlı kullanıcıya ait hesap bulunamadı, lütfen tekrar deneyin"
                        self.errorText.isHidden = false
                    case AuthErrorCode.networkError.rawValue:
                        print("Could not reach database, check Internet connection")
                        self.errorText.text = "Sunucuya ulaşılamadı, lütfen İnternet bağlantınızı kontrol edin"
                        self.errorText.isHidden = false
                    case AuthErrorCode.wrongPassword.rawValue:
                        print("Saved user's password is wrong")
                        self.errorText.text = "Kayıtlı kullanıcıya ait şifre yanlış, lütfen tekrar deneyin"
                        self.errorText.isHidden = false
                    case AuthErrorCode.invalidEmail.rawValue:
                        print("Saved user has an invalid email")
                        self.errorText.text = "Kayıtlı kullanıcıya ait e-posta adresi geçerli değil, lütfen tekrar deneyin"
                        self.errorText.isHidden = false
                    default:
                        print(errorCode)
                        self.errorText.text = "Kayıtlı kullanıcı olarak giriş yapılamadı, lütfen tekrar deneyin"
                        self.errorText.isHidden = false
                    }
                    self.loadingView.removeFromSuperview()
                    self.enableUserInteraction()
                }
                else {
                    print("Login via saved user successful")
                    
                    self.loadingView.removeFromSuperview()
                    self.enableUserInteraction()
                    
                    self.performSegue(withIdentifier: "homeSegue", sender: self)
                }
            
            }
        }
    }
    
    
}
