//
//  ResultsViewController.swift
//  TarihAvi
//
//  Created by Cem Kupeli on 23.04.2020.
//  Copyright © 2020 Cem Kupeli. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class ResultsViewController: UIViewController {

    @IBOutlet weak var correctAnswersText: UILabel!
    @IBOutlet weak var incorrectAnswersText: UILabel!
    @IBOutlet weak var pointsEarnedText: UILabel!
    @IBOutlet weak var updatedCategoryScoreText: UILabel!
    @IBOutlet weak var updatedGeneralScoreText: UILabel!
    @IBOutlet weak var returnButton: UIButton!
    
    var updatedCategoryScore = 0
    var updatedTotalScore = 0
    let currentCategory = GlobalVariables.categoryName
    
    let errorView = UIView()
    let loadingView = UIView()

    var checks = ["userCategoryScoresReceived": false, "userAwardsReceived": false] {
        didSet {
            if checks == ["userCategoryScoresReceived": true, "userAwardsReceived": true] {

                print("Updated total score: \(updatedTotalScore)")
                updateUserCategoryScores()
                
                addAwardView()
                
                correctAnswersText.text = "Doğru cevap sayısı: \(GlobalVariables.correctAnswers)"
                incorrectAnswersText.text = "Yanlış cevap sayısı: \(GlobalVariables.incorrectAnswers)"
                pointsEarnedText.text = "Kazanılan puan: \(GlobalVariables.gameScore)"
                updatedCategoryScoreText.text = "Yeni kategori puanı: \(updatedCategoryScore)"
                updatedGeneralScoreText.text = "Yeni genel puan: \(updatedTotalScore)"
                
                loadingView.removeFromSuperview()
            }
        }
    }
    
    var userCategoryScores: [String:Int] = [:] {
        didSet {
            if userCategoryScores.count == 2 {
                checks["userCategoryScoresReceived"] = true
                print("User category scores received, checks: \(checks)")
                // Prints the user's current score in the category, and then updates these scores (not in the dictionary but in the updatedTotalScore and updatedCategoryScore variables, otherwise the didSet would fire again)
                let currentCategoryScore = userCategoryScores[currentCategory]!
                print("Current category score: \(currentCategoryScore)")
                
                updatedTotalScore = userCategoryScores["totalScore"]! + GlobalVariables.gameScore
                updatedCategoryScore = currentCategoryScore + GlobalVariables.gameScore
                print("Updated category score: \(updatedCategoryScore)")
                
                // The getUserAwards function calls checkForReceivedAwards, which uses the user's category score, so it must be called after the category score is pulled from the database
                getUserAwards()
            }
        }
    }
    var userAwards: [String:Bool] = [:] {
        didSet {
            if userAwards.count == 4 {
                checkForReceivedAwards()
                checks["userAwardsReceived"] = true
                print("User awards received and checked if any award is received, checks: \(checks)")
            }
        }
    }
    // Set as equal to the number of the award (I, II, III, or IV) the user receives if the user does receive any, otherwise it remains empty and the nextAwardNumber variable is set equal to the next possible award's number
    var receivedAwardNumber = ""
    var nextAwardNumber = ""
    
    override func viewDidLoad() {
    
        returnButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        addLoadingView()
        getUserCategoryScores()
        super.viewDidLoad()
        
    }
    
    override var prefersStatusBarHidden: Bool {
           return true
       }
    // Retrieves the user's score in this category and their total score
    func getUserCategoryScores() {
        
        userCategoryScores = [:]
        
        let database = Firestore.firestore()
        let scoresRef = database.collection("users").document(GlobalVariables.currentUserID).collection("scores")

        scoresRef.document(currentCategory).getDocument { (DocumentSnapshot, error) in
            if error != nil {
                print(error ?? "error")
                self.loadingView.removeFromSuperview()
                self.addErrorView()
            }
            else {
                self.userCategoryScores[self.currentCategory] = (DocumentSnapshot!["userScore"] as! Int)
            }
        }

        scoresRef.document("totalScore").getDocument { (DocumentSnapshot, error) in
            if error != nil {
                print(error ?? "error")
            }
            else {
                self.userCategoryScores["totalScore"] = (DocumentSnapshot!["userScore"] as! Int)
            }
        }
    }
    
    func updateUserCategoryScores() {
        
        let database = Firestore.firestore()

        let scoresRef = database.collection("users").document(GlobalVariables.currentUserID).collection("scores")
        
        scoresRef.document(currentCategory).updateData(["userScore" : updatedCategoryScore])
        scoresRef.document("totalScore").updateData(["userScore" : updatedTotalScore])
        
        }
    
    func getUserAwards() {
        
        userAwards = [:]
        
        let database = Firestore.firestore()
        
        database.collection("users").document(GlobalVariables.currentUserID).collection("awards").document("userAwards").getDocument { (DocumentSnapshot, error) in
            if error != nil {
                print(error ?? "error")
                self.loadingView.removeFromSuperview()
                self.addErrorView()
            }
            else {
                
                for number in ["I", "II", "III", "IV"] {
                    
                    self.userAwards["\(self.currentCategory) \(number)"] = (DocumentSnapshot!["\(self.currentCategory) \(number)"] as! Bool)
                    
                }
                print("User awards: \(self.userAwards)")
                
            }
        }
        
    }
    
    // Checks whether the user has won an award in the current category, updates the user's award data if any award is received, and sets the variable receivedAward to whichever award the user has received (if any)
    func checkForReceivedAwards() {
        
        let database = Firestore.firestore()
        // The userAwards dictionary is not altered as to not fire the didSet
        if updatedCategoryScore < 2500 {
            nextAwardNumber = "I"
        }
        if updatedCategoryScore >= 2500 && updatedCategoryScore < 5000 {
            if userAwards["\(currentCategory) I"] == false {
                database.collection("users").document(GlobalVariables.currentUserID).collection("awards").document("userAwards").updateData([
                    "\(currentCategory) I" : true
                ])
                print("The user has won the award *\(currentCategory) I*")
                receivedAwardNumber = "I"
            }
            else {
                nextAwardNumber = "II"
            }
        }
        else if updatedCategoryScore >= 5000 && updatedCategoryScore < 7500 {
            if userAwards["\(currentCategory) II"] == false {
                database.collection("users").document(GlobalVariables.currentUserID).collection("awards").document("userAwards").updateData([
                    "\(currentCategory) II" : true
                ])
                print("The user has won the award *\(currentCategory) II*")
                receivedAwardNumber = "II"
            }
            else {
                nextAwardNumber = "III"
            }
        }
        else if updatedCategoryScore >= 7500 && updatedCategoryScore < 10000 {
            if userAwards["\(currentCategory) III"] == false {
                database.collection("users").document(GlobalVariables.currentUserID).collection("awards").document("userAwards").updateData([
                    "\(currentCategory) III" : true
                ])
                print("The user has won the award *\(currentCategory) III*")
                receivedAwardNumber = "III"
            }
            else {
                nextAwardNumber = "IV"
            }
        }
        else if updatedCategoryScore >= 10000 {
            if userAwards["\(currentCategory) IV"] == false {
                database.collection("users").document(GlobalVariables.currentUserID).collection("awards").document("userAwards").updateData([
                    "\(currentCategory) IV" : true
                ])
                print("The user has won the award *\(currentCategory) IV*")
                receivedAwardNumber = "IV"
            }
            else {
                // There is no fifth award, but setting nextAwardNumber to five will result in the view displaying that there are no more awards to be won in this category
                nextAwardNumber = "V"
            }
        }
        
        
    }
    
    func addAwardView() {
        
        let awardView = UIView()
        view.addSubview(awardView)
        
        awardView.topAnchor.constraint(equalTo: updatedGeneralScoreText.bottomAnchor, constant: 20).isActive = true
        awardView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        awardView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        awardView.bottomAnchor.constraint(equalTo: returnButton.topAnchor).isActive = true
        
        awardView.translatesAutoresizingMaskIntoConstraints = false
        
        let awardImageFrame = UIView()
        awardView.addSubview(awardImageFrame)
        
        awardImageFrame.centerXAnchor.constraint(equalTo: awardView.centerXAnchor).isActive = true
        awardImageFrame.topAnchor.constraint(equalTo: awardView.topAnchor).isActive = true
        awardImageFrame.widthAnchor.constraint(equalTo: awardView.widthAnchor, multiplier: 0.25, constant: 2).isActive = true
        awardImageFrame.heightAnchor.constraint(equalTo: awardImageFrame.widthAnchor).isActive = true
        
        awardImageFrame.translatesAutoresizingMaskIntoConstraints = false
        
        awardImageFrame.backgroundColor = .black
        
        let awardImage = UIView()
        awardView.addSubview(awardImage)
        
        awardImage.centerXAnchor.constraint(equalTo: awardView.centerXAnchor).isActive = true
        awardImage.topAnchor.constraint(equalTo: awardView.topAnchor, constant: 2).isActive = true
        awardImage.widthAnchor.constraint(equalTo: awardView.widthAnchor, multiplier: 0.25, constant: -2).isActive = true
        awardImage.heightAnchor.constraint(equalTo: awardImage.widthAnchor).isActive = true
        
        awardImage.translatesAutoresizingMaskIntoConstraints = false
        
        // Contains all the award colors that can  be assigned to any particular category
        switch SetAssigner.awardColors[currentCategory] {
        case "yellow":
            awardImage.backgroundColor = .yellow
        case "green":
            awardImage.backgroundColor = .green
        case "red":
            awardImage.backgroundColor = .red
        case "blue":
            awardImage.backgroundColor = .blue
        default:
            awardImage.backgroundColor = .blue
        }
        // If a new award hasn't been received, the award image will be gray to indicate that the next award hasn't been unlocked yet. However, if all awards have been unlocked (where nextAwardNumber == "V") then the award image will be hidden
        if receivedAwardNumber.isEmpty {
            if nextAwardNumber != "V" {
                awardImage.backgroundColor = .gray
            }
            else {
                awardImage.isHidden = true
                awardImageFrame.isHidden = true
            }
        }
        
        let awardNumber = UILabel()
        awardImage.addSubview(awardNumber)
        
        awardNumber.topAnchor.constraint(equalTo: awardImage.topAnchor, constant: 10).isActive = true
        awardNumber.heightAnchor.constraint(equalTo: awardImage.heightAnchor, constant: -20).isActive = true
        awardNumber.leftAnchor.constraint(equalTo: awardImage.leftAnchor, constant: 10).isActive = true
        awardNumber.rightAnchor.constraint(equalTo: awardImage.rightAnchor, constant: -10).isActive = true
        
        awardNumber.translatesAutoresizingMaskIntoConstraints = false
        
        awardNumber.adjustsFontSizeToFitWidth = true
        awardNumber.font = UIFont(name: "Times New Roman", size: 40)
        awardNumber.textAlignment = .center
        awardNumber.textColor = .black
        // If there is an award received, the display shows the number of the award received. Otherwise, the number of the next possible award is displayed
        if receivedAwardNumber.isEmpty {
            awardNumber.text = nextAwardNumber
        }
        else {
            awardNumber.text = receivedAwardNumber
        }
        
        let awardTitle = UILabel()
        awardView.addSubview(awardTitle)
        
        awardTitle.topAnchor.constraint(equalTo: awardImage.bottomAnchor, constant: 10).isActive = true
        awardTitle.leadingAnchor.constraint(equalTo: awardView.leadingAnchor, constant: 10).isActive = true
        awardTitle.widthAnchor.constraint(equalTo: awardView.widthAnchor, constant: -20).isActive = true
        awardTitle.heightAnchor.constraint(equalTo: awardView.heightAnchor, multiplier: 0.30, constant: -10).isActive = true
        
        awardTitle.translatesAutoresizingMaskIntoConstraints = false
        
        awardTitle.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        awardTitle.adjustsFontSizeToFitWidth = true
        awardTitle.textAlignment = .center
        awardTitle.textColor = .black
        if receivedAwardNumber.isEmpty {
            if nextAwardNumber != "V" {
                awardTitle.text = "Bir sonraki ödül: \(currentCategory) \(nextAwardNumber)"
            }
            else {
                awardTitle.text = "Bu kategorideki tüm ödülleri kazandınız!"
            }
        }
        else {
            awardTitle.text = "\(currentCategory) \(receivedAwardNumber) ödülünü kazandınız!"
        }
        
        let awardDescription = UILabel()
        awardView.addSubview(awardDescription)
        
        awardDescription.bottomAnchor.constraint(equalTo: awardView.bottomAnchor, constant: -10).isActive = true
        awardDescription.leadingAnchor.constraint(equalTo: awardView.leadingAnchor, constant: 5).isActive = true
        awardDescription.widthAnchor.constraint(equalTo: awardView.widthAnchor, constant: -10).isActive = true
        awardDescription.heightAnchor.constraint(equalTo: awardView.heightAnchor, multiplier: 0.45, constant: -20).isActive = true
        
        awardDescription.translatesAutoresizingMaskIntoConstraints = false
        
        awardDescription.font = UIFont.systemFont(ofSize: 30, weight: .regular)
        awardDescription.adjustsFontSizeToFitWidth = true
        awardDescription.textAlignment = .center
        awardDescription.textColor = .black
        if receivedAwardNumber.isEmpty {
            if nextAwardNumber != "V" {
                awardDescription.text = SetAssigner.awardDescriptions["\(currentCategory) \(nextAwardNumber)"]
            }
            else {
                awardDescription.text = ""
            }
        }
        else {
            awardDescription.text = SetAssigner.awardDescriptions["\(currentCategory) \(receivedAwardNumber)"]
        }
        
    }
    
    @IBAction func returnPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        self.dismiss(animated: false) {
            GlobalVariables.currentQuestionsVC.resultsDismissed = true
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
        
       print("Recalling database methods")
       if GlobalVariables.soundEffectsOn == true {
           GlobalVariables.soundEffect.play()
       }
       errorView.removeFromSuperview()
       addLoadingView()
       checks = ["userCategoryScoresReceived": false, "userAwardsReceived": false]
       getUserCategoryScores()
        
    }
    
}
