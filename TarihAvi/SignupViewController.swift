//
//  SignupViewController.swift
//  TarihAvi
//
//  Created by Cem Kupeli on 7.04.2020.
//  Copyright © 2020 Cem Kupeli. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SignupViewController: UIViewController {
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var surnameText: UITextField!
    @IBOutlet weak var usernameText: UITextField!
    @IBOutlet weak var emailText: UITextField!
    @IBOutlet weak var password1Text: UITextField!
    @IBOutlet weak var password2Text: UITextField!
    @IBOutlet weak var errorText: UILabel!
    @IBOutlet weak var signupButton: UIButton!
    @IBOutlet weak var returnButton: UIButton!
    
    let loadingView = UIView()
    
    // The usernames that are currently in use (will be retrieved from database)
    var currentUsernames: [String] = []
    
    var usernamesReceived = false {
        didSet {
            // Checks if the current usernames contain the username entered by the user
            if currentUsernames.contains(usernameText.text!) {
                errorText.text = "Kullanıcı adı başka bir kullanıcı tarafından kullanılıyor"
                errorText.isHidden = false
            }
                
            else if password1Text.text == password2Text.text {
                
                addLoadingView()
                disableUserInteraction()

                Auth.auth().createUser(withEmail: emailText.text!, password: password2Text.text!) { (results, error) in
                    if error != nil {
                        let errorCode = (error! as NSError).code
                        print("Error code: \(errorCode)")
                        switch errorCode {
                        case AuthErrorCode.invalidEmail.rawValue:
                            print("Invalid email")
                            self.errorText.text = "Lütfen geçerli bir e-posta adresi girdiğinizden emin olun"
                            self.errorText.isHidden = false
                        case AuthErrorCode.emailAlreadyInUse.rawValue:
                            print("This email is already in use")
                            self.errorText.text = "Bu e-posta adresi çoktan kullanılıyor, lütfen başka bir e-posta adresi kullanın"
                            self.errorText.isHidden = false
                        case AuthErrorCode.networkError.rawValue:
                            print("Could not reach database, check Internet connection")
                            self.errorText.text = "Sunucuya ulaşılamadı, lütfen İnternet bağlantınızı kontrol edin"
                            self.errorText.isHidden = false
                        case AuthErrorCode.weakPassword.rawValue:
                            print("User has entered a weak password")
                            self.errorText.text = "Şifreniz en az altı karakter içermeli"
                            self.errorText.isHidden = false
                        default:
                            print(errorCode)
                            self.errorText.text = "Kullanıcı oluşturulamadı"
                            self.errorText.isHidden = false
                        }
                        self.loadingView.removeFromSuperview()
                        self.enableUserInteraction()
                    }
                    else {
                        print("User created")
                        print("User information:")
                        print(self.nameText.text!)
                        print(self.surnameText.text!)
                        print(self.usernameText.text!)
                        print(self.emailText.text!)
                        print(self.password1Text.text!)
                        print(self.password2Text.text!)
                        print("\n")
                    
                        let database = Firestore.firestore()
                        print(results!.user.uid)
                        
                        database.collection("users").document(results!.user.uid).setData([
                            "user_email": self.emailText.text!,
                            "user_isAdmin": false,
                            "user_name": self.nameText.text!,
                            "user_surname": self.surnameText.text!,
                            "user_username": self.usernameText.text!,
                            "recordedCategories": SetAssigner.categories.count
                        ]) { (error2) in
                            if error2 != nil {
                                print(error2 ?? "error")
                                print("6")
                            }
                            else {
                                print("User info added to database")
                            }
                        }
                        SetAssigner.addSetDataToUser(currentCategories: SetAssigner.categories, userID: results!.user.uid, target: self)

                    }
                
                }
            
            }
            else {
                errorText.text = "Şifreler eşleşmiyor, lütfen aynı şifreyi girdiğinizden emin olun"
                errorText.isHidden = false
            }
        }
    }
    
    var setDataAdded = false {
        didSet {
            if setDataAdded == true {
                print("Set data added to user, dismissing the sign-up view")
                loadingView.removeFromSuperview()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        
        signupButton.titleLabel?.adjustsFontSizeToFitWidth = true
        returnButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        enableUserInteraction()
        errorText.isHidden = true
        
        // Sets the email text field's keyboard type
        emailText.keyboardType = .emailAddress
        
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func signupPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        errorText.isHidden = true
        if nameText.text == "" || surnameText.text == "" || usernameText.text == "" || emailText.text == "" || password1Text.text == "" || password2Text.text == "" {
            errorText.text = "Lütfen boş alanları doldurun"
            errorText.isHidden = false
        }
        else {
            // Checks whether the name and surname are longer than 50 characters
            if nameText.text!.count > 50 {
                errorText.text = "Adınız için en fazla 50 karakter kullanabilirsiniz"
                errorText.isHidden = false
            }
            else if surnameText.text!.count > 50 {
                errorText.text = "Soyadınız için en fazla 50 karakter kullanabilirsiniz"
                errorText.isHidden = false
            }
            // Checks if the username is longer than 10 characters
            else if usernameText.text!.count > 10 {
                errorText.text = "Kullanıcı adınız en fazla 10 karakter uzunluğunda olabilir"
                errorText.isHidden = false
            }
            // Checks if the username contains a whitespace
            else if usernameText.text!.contains(" ") {
                errorText.text = "Lütfen kullanıcı adınızda boşluk olmadığından emin olun"
                errorText.isHidden = false
            }
            // Checks if the username is unique (call sets usernamesReceived to true once the usernames are received from the database
            else {
                
                checkUniqueUsername(username: usernameText.text!)
                
            }
        }

    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        
        self.dismiss(animated: true, completion: nil)
        
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
    
    func disableUserInteraction() {
        
        nameText.isUserInteractionEnabled = false
        surnameText.isUserInteractionEnabled = false
        usernameText.isUserInteractionEnabled = false
        emailText.isUserInteractionEnabled = false
        password1Text.isUserInteractionEnabled = false
        password2Text.isUserInteractionEnabled = false
        signupButton.isUserInteractionEnabled = false
        returnButton.isUserInteractionEnabled = false
        
    }
    
    func enableUserInteraction() {
        
        nameText.isUserInteractionEnabled = true
        surnameText.isUserInteractionEnabled = true
        usernameText.isUserInteractionEnabled = true
        emailText.isUserInteractionEnabled = true
        password1Text.isUserInteractionEnabled = true
        password2Text.isUserInteractionEnabled = true
        signupButton.isUserInteractionEnabled = true
        returnButton.isUserInteractionEnabled = true
        
    }

    func checkUniqueUsername(username: String) {
        
        let database = Firestore.firestore()
        
        database.collection("users").getDocuments { (QuerySnapshot, error) in
            if error != nil {
                print(error ?? "error")
            }
            else {
                
                for document in QuerySnapshot!.documents {
                    let thisUsername = document["user_username"] as! String
                    self.currentUsernames.append(thisUsername)
                }
                self.usernamesReceived = true
            }
        }
    }
    
}
