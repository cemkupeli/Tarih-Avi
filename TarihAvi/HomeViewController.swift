//
//  HomeViewController.swift
//  TarihAvi
//
//  Created by Cem Kupeli on 7.04.2020.
//  Copyright © 2020 Cem Kupeli. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class HomeViewController: UIViewController {

    @IBOutlet weak var leaderboardButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var selectCategoryButton: UIButton!
    @IBOutlet weak var helpButton: UIButton!
    
    let loadingView = UIView()
    let errorView = UIView()
    
    // 5 checks: get number of users, check for new category data, check for new set data, get award descriptions, check whether user is an admin by getting the user's data, get active categories
    // This boolean assures that the first condition inside the checks' didSet only gets fired once, so that checkForNewSetData isn't called multiplte times
    var beganCheckingForSetData = false
    var checks = ["numberOfUsersReceived": false, "categoryDataChecked": false, "setDataChecked": false, "awardDescriptionsReceived": false, "adminChecked": false, "activeCategoriesReceived": false] {
        didSet {
            if checks["categoryDataChecked"] == true && beganCheckingForSetData == false {
                beganCheckingForSetData = true
                // Since checkForNewSetData assumes that the user has category data for all current categories, it must be called after checkForNewCategoryData is called.
                SetAssigner.checkForNewSetData(userID: GlobalVariables.currentUserID, target: self)
            }
            if checks == ["numberOfUsersReceived": true, "categoryDataChecked": true, "setDataChecked": true, "awardDescriptionsReceived": true, "adminChecked": true, "activeCategoriesReceived": true] {
                // remove loading view and allow user interaction (for this and other views where the loading view is implemented, add the addLoadingView and enable/disableUserInteraction methods
                print("All checks completed, checks: \(checks)")
                loadingView.removeFromSuperview()
                enableUserInteraction()
                
            }
        }
    }
    
    // The SetAssigner methods set this boolean to true if they encounter an error while accessing the database
    var encounteredError = false {
        didSet {
            if encounteredError == true {
        
                disableUserInteraction()
                loadingView.removeFromSuperview()
                addErrorView()
                encounteredError = false

            }
        }
    }
    
    var expectedNewCategories = 1000 {
        didSet {
            print("Expected new categories: \(expectedNewCategories)")
            if expectedNewCategories == 0 {
                checks["categoryDataChecked"] = true
                print("Checked for new category data, home checks: \(checks)")
            }
        }
    }
    
    override func viewDidLoad() {
        
        selectCategoryButton.titleLabel?.adjustsFontSizeToFitWidth = true
        helpButton.titleLabel?.adjustsFontSizeToFitWidth = true
        leaderboardButton.titleLabel?.adjustsFontSizeToFitWidth = true
        settingsButton.titleLabel?.adjustsFontSizeToFitWidth = true
        returnButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        disableUserInteraction()
        addLoadingView()
        GlobalVariables.currentUserID = (Auth.auth().currentUser!.uid)
        print("Current user ID: \(GlobalVariables.currentUserID)")
        
        SetAssigner.checkForNewCategoryData(userID: GlobalVariables.currentUserID, target: self)
        SetAssigner.getActiveCategories(target: self)
        SetAssigner.getAwardDescriptions(target: self)
        checkAdminAndNumberOfUsers()
        
        super.viewDidLoad()

    }
    

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func settingsPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        performSegue(withIdentifier: "settingsSegue", sender: self)
        
    }
    
    @IBAction func logoutButtonPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        do {
            try Auth.auth().signOut()
        } catch let signoutError as NSError {
            print("Error signing out: \(signoutError)")
        }
        
        
        
        self.dismiss(animated: true, completion: nil)
        
    }
    @IBAction func categoryButtonPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        performSegue(withIdentifier: "categorySegue", sender: self)
        
    }
    
    func checkAdminAndNumberOfUsers() {
        
        let database = Firestore.firestore()
        
        let userRef = database.collection("users").document(GlobalVariables.currentUserID)
        userRef.getDocument { (documentSnapshot, error) in
            if error != nil {
                print(error ?? "error")
                self.encounteredError = true
            }
            else {
                
                GlobalVariables.userEmail = (documentSnapshot?["user_email"] as? String)!
                GlobalVariables.userUsername = (documentSnapshot?["user_username"] as? String)!
                GlobalVariables.userIsAdmin = (documentSnapshot?["user_isAdmin"] as? Bool)!
               
                self.checks["adminChecked"] = true
                print("Received user data and checked whether the user is an admin, checks: \(self.checks)")
                
            }
            
        }
        
        database.collection("users").getDocuments { (QuerySnapshot, error) in
            if error != nil {
                print(error ?? "error")
            }
            else {
                GlobalVariables.numberOfUsers = 0
                for _ in QuerySnapshot!.documents {
                    GlobalVariables.numberOfUsers += 1
                }
            }
            print("Number of users: \(GlobalVariables.numberOfUsers)")
            self.checks["numberOfUsersReceived"] = true
            print("Number of users received, checks: \(self.checks)")
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
        errorView.removeFromSuperview()
        addLoadingView()
        beganCheckingForSetData = false
        checks = ["numberOfUsersReceived": false, "categoryDataChecked": false, "setDataChecked": false, "awardDescriptionsReceived": false, "adminChecked": false, "activeCategoriesReceived": false]
        SetAssigner.checkForNewCategoryData(userID: GlobalVariables.currentUserID, target: self)
        SetAssigner.getActiveCategories(target: self)
        SetAssigner.getAwardDescriptions(target: self)
        checkAdminAndNumberOfUsers()
    }
    
    @IBAction func leaderboardPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        performSegue(withIdentifier: "leaderboardSegue", sender: self)
        
    }
    
    @IBAction func helpPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        performSegue(withIdentifier: "helpSegue", sender: self)
        
    }
    
    
    func disableUserInteraction() {
        
        settingsButton.isUserInteractionEnabled = false
        returnButton.isUserInteractionEnabled = false
        selectCategoryButton.isUserInteractionEnabled = false
        
    }
    
    func enableUserInteraction() {
        
        settingsButton.isUserInteractionEnabled = true
        returnButton.isUserInteractionEnabled = true
        selectCategoryButton.isUserInteractionEnabled = true
        
    }
}
