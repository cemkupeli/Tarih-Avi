//
//  LeaderboardViewController.swift
//  TarihAvi
//
//  Created by Cem Kupeli on 25.05.2020.
//  Copyright © 2020 Cem Kupeli. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class LeaderboardViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    let scrollView = UIScrollView()
    let stackView = UIStackView()
    
    let examineScrollView = UIScrollView()
    let examineStackView = UIStackView()
    
    let loadingView = UIView()
    let errorView = UIView()
    
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var returnButton: UIButton!
    
    // the dictionary where the username-score pairs are stored
    let database = Firestore.firestore()
    
    var usersRead = 0 {
        didSet {
            if usersRead == GlobalVariables.numberOfUsers {
                print("User scores dictionary: \(self.userScores)")
                sortUserScores()
                updateLeaderboardView()
                loadingView.removeFromSuperview()
                enableUserInteraction()
            }
        }
    }
    // The number of users that have score data for the current category being displayed
    var validUsers = 0
    var userScores: [String:Int] = [:]
    var userIDs: [String:String] = [:]
    var scoresArray: [Int] = []
    var usernamesArray: [String] = []
    
    var selectedCategory = "Toplam Puan"
    
    // If the addErrorView method is called, these variables are set to values that help decide what the retry button will do
    var retryMethod = ""
    var retryCategory = ""

    override func viewDidLoad() {
        
        returnButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        disableUserInteraction()
        addLoadingView()
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.reloadAllComponents()
        pickerView.selectRow(0, inComponent: 0, animated: false)
        getUserScores(category: "totalScore")

        super.viewDidLoad()

    }
    
    func updateLeaderboardView() {
        
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        // to delete previous views before adding in the new views
        for view in stackView.subviews {
            stackView.removeArrangedSubview(view)
        }
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10).isActive = true
        scrollView.topAnchor.constraint(equalTo: pickerView.bottomAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10).isActive = true
        scrollView.backgroundColor = .white
        scrollView.alpha = 0.7
        
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = true
        scrollView.canCancelContentTouches = true
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .center
        stackView.distribution = .equalSpacing
        
        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 5).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -5).isActive = true
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor).isActive = true
        
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -10).isActive = true
    
        stackView.isUserInteractionEnabled = true
        
        for number in 0...validUsers - 1 {
            
            let userView = UIView()
            
            stackView.addArrangedSubview(userView)
            userView.heightAnchor.constraint(equalToConstant: 100).isActive = true
            userView.widthAnchor.constraint(equalTo: stackView.widthAnchor).isActive = true
            
            let usernameLabel = UILabel()
            userView.addSubview(usernameLabel)
            usernameLabel.text = "\(number + 1). \(usernamesArray[number])"
            usernameLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
            usernameLabel.textColor = .black
            usernameLabel.adjustsFontSizeToFitWidth = true
            
            usernameLabel.translatesAutoresizingMaskIntoConstraints = false
            
            usernameLabel.leadingAnchor.constraint(equalTo: userView.leadingAnchor, constant: 10).isActive = true
            usernameLabel.widthAnchor.constraint(equalTo: userView.widthAnchor, multiplier: 0.4, constant: -10).isActive = true
            usernameLabel.topAnchor.constraint(equalTo: userView.topAnchor, constant: 10).isActive = true
            usernameLabel.bottomAnchor.constraint(equalTo: userView.bottomAnchor, constant: -10).isActive = true
            
            usernameLabel.isUserInteractionEnabled = false
            
            let examineButton = UIButton()
            userView.addSubview(examineButton)
            examineButton.setTitle("İncele", for: .normal)
            examineButton.setTitleColor(.black, for: .normal)
            examineButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
            examineButton.titleLabel?.adjustsFontSizeToFitWidth = true
            
            examineButton.translatesAutoresizingMaskIntoConstraints = false
            
            examineButton.widthAnchor.constraint(equalTo: userView.widthAnchor, multiplier: 0.3).isActive = true
            examineButton.trailingAnchor.constraint(equalTo: userView.trailingAnchor).isActive = true
            examineButton.topAnchor.constraint(equalTo: userView.topAnchor, constant: 10).isActive = true
            examineButton.bottomAnchor.constraint(equalTo: userView.bottomAnchor, constant: -10).isActive = true
            
            examineButton.tag = number
            examineButton.addTarget(self, action: #selector(examineButtonPressed), for: .touchUpInside)
            examineButton.isUserInteractionEnabled = true
            
            let scoreLabel = UILabel()
            userView.addSubview(scoreLabel)
            scoreLabel.text = "Skor: \(scoresArray[number])"
            scoreLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
            scoreLabel.textColor = .black
            scoreLabel.adjustsFontSizeToFitWidth = true
            
            scoreLabel.translatesAutoresizingMaskIntoConstraints = false
            
            scoreLabel.widthAnchor.constraint(equalTo: userView.widthAnchor, multiplier: 0.3).isActive = true
            scoreLabel.trailingAnchor.constraint(equalTo: examineButton.leadingAnchor).isActive = true
            scoreLabel.topAnchor.constraint(equalTo: userView.topAnchor, constant: 10).isActive = true
            scoreLabel.bottomAnchor.constraint(equalTo: userView.bottomAnchor, constant: -10).isActive = true
            
            scoreLabel.isUserInteractionEnabled = false
            
            // The user's own userView will be a different color for easier identification
            if usernamesArray[number] == GlobalVariables.userUsername {
                userView.backgroundColor = UIColor(named: "8")
            }
            else {
                userView.backgroundColor = UIColor(named: "7")
                usernameLabel.textColor = .white
                examineButton.setTitleColor(.white, for: .normal)
                scoreLabel.textColor = .white
            }
            
        }
        
    }
    
    func sortUserScores() {
        
        usernamesArray = []
        scoresArray = []
        
        var unsortedUsernames: [String] = []
        var unsortedScores: [Int] = []
        
        for user in userScores {
            unsortedUsernames.append(user.key)
            unsortedScores.append(user.value)
        }
        
        for _ in 0...userScores.count - 1 {
            
            let indexOfMaximumScore = unsortedScores.firstIndex(of: unsortedScores.max()!)!
            scoresArray.append(unsortedScores.max()!)
            usernamesArray.append(unsortedUsernames[indexOfMaximumScore])
            unsortedScores.remove(at: indexOfMaximumScore)
            unsortedUsernames.remove(at: indexOfMaximumScore)

        }
        
        print("Usernames: \(usernamesArray)")
        print("Scores: \(scoresArray)")
        
    }
    
    func getUserScores(category: String) {
        
        validUsers = 0
        usersRead = 0
        userScores = [:]
        
        database.collection("users").getDocuments { (QuerySnapshot, error) in
            if error != nil {
                print(error ?? "error")
                self.retryMethod = "getUserScores"
                self.retryCategory = category
                self.loadingView.removeFromSuperview()
                self.disableUserInteraction()
                self.addErrorView(examineButtonPressed: false)
            }
            else {
                for document in QuerySnapshot!.documents {
                    
                    self.database.collection("users").document(document.documentID).collection("scores").document(category).getDocument { (DocumentSnapshot, error) in
                        if error != nil {
                            print(error ?? "error")
                        }
                        else {
                            if DocumentSnapshot!.exists {
                                self.userScores[(document["user_username"] as! String)] = (DocumentSnapshot!["userScore"] as! Int)
                                self.userIDs[(document["user_username"] as! String)] = document.documentID
                                self.validUsers += 1
                            }
                            self.usersRead += 1
                        }
                    }
                    
                }
            }
        }
        
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return SetAssigner.activeCategories.count + 1
        
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        view.addSubview(label)
        if row == 0 {
        
            label.text = "Toplam Puan"
            selectedCategory = "totalScore"

        }
        else {

            label.text = SetAssigner.activeCategories[row-1]
            selectedCategory = SetAssigner.activeCategories[row-1]
        
        }
        
        return view
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        print("Selected new row")
        addLoadingView()
        disableUserInteraction()
        getUserScores(category: selectedCategory)
        
    }

    @IBAction func backButtonPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func examineButtonPressed(sender: UIButton) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        disableUserInteraction()
        addLoadingView()
        let selectedUsername = usernamesArray[sender.tag]
        let selectedUserID = userIDs[selectedUsername]

        var awardsReceived: [String] = []
        
        // clears the examine scroll and stack view from their previous subviews
        for view in examineScrollView.subviews {
            view.removeFromSuperview()
        }
        for view in examineStackView.subviews {
            view.removeFromSuperview()
        }
        
        database.collection("users").document(selectedUserID!).collection("awards").document("userAwards").getDocument { (DocumentSnapshot, error) in
            if error != nil {
                print(error ?? "error")
                self.retryMethod = "examineButtonPressed"
                self.loadingView.removeFromSuperview()
                self.addErrorView(examineButtonPressed: true)
            }
            else {
                
                for award in SetAssigner.awards {
                
                    if DocumentSnapshot![award] == nil {
                        
                    }
                    else {
                        let currentAwardReceived = DocumentSnapshot![award] as! Bool
                        if currentAwardReceived == true {
                            awardsReceived.append(award)
                        }
                    }
    
                }
                
                self.view.addSubview(self.examineScrollView)
                self.examineScrollView.addSubview(self.examineStackView)
            
                self.examineScrollView.translatesAutoresizingMaskIntoConstraints = false
                
                self.examineScrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
                self.examineScrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
                self.examineScrollView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 100).isActive = true
                self.examineScrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -20).isActive = true
                self.examineScrollView.backgroundColor = UIColor(named: "4")
                self.examineScrollView.alpha = 1.0
                
                self.examineScrollView.isScrollEnabled = true
                self.examineScrollView.showsVerticalScrollIndicator = true
                self.examineScrollView.canCancelContentTouches = true
                self.examineScrollView.isUserInteractionEnabled = true
                
                self.examineStackView.translatesAutoresizingMaskIntoConstraints = false
                self.examineStackView.axis = .vertical
                self.examineStackView.spacing = 10
                self.examineStackView.alignment = .center
                self.examineStackView.distribution = .equalSpacing
                
                self.examineStackView.leadingAnchor.constraint(equalTo: self.examineScrollView.leadingAnchor, constant: 5).isActive = true
                self.examineStackView.trailingAnchor.constraint(equalTo: self.examineScrollView.trailingAnchor, constant: -5).isActive = true
                self.examineStackView.topAnchor.constraint(equalTo: self.examineScrollView.topAnchor, constant: 60).isActive = true
                self.examineStackView.bottomAnchor.constraint(equalTo: self.examineScrollView.bottomAnchor).isActive = true
                
                self.examineStackView.widthAnchor.constraint(equalTo: self.examineScrollView.widthAnchor, constant: -10).isActive = true
            
                self.examineStackView.isUserInteractionEnabled = false
                
                let returnButton = UIButton()
                self.examineScrollView.addSubview(returnButton)
                returnButton.setTitle("Geri Dön", for: .normal)
                returnButton.setTitleColor(.black, for: .normal)
                returnButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
                returnButton.titleLabel?.adjustsFontSizeToFitWidth = true
                
                returnButton.translatesAutoresizingMaskIntoConstraints = false
                
                returnButton.widthAnchor.constraint(equalTo: self.examineScrollView.widthAnchor, multiplier: 0.4, constant: -5).isActive = true
                returnButton.trailingAnchor.constraint(equalTo: self.examineScrollView.trailingAnchor, constant: -5).isActive = true
                returnButton.topAnchor.constraint(equalTo: self.examineScrollView.topAnchor, constant: 5).isActive = true
                returnButton.bottomAnchor.constraint(equalTo: self.examineStackView.topAnchor, constant: -5).isActive = true
                
                returnButton.addTarget(self, action: #selector(self.returnFromExamine), for: .touchUpInside)
                returnButton.isUserInteractionEnabled = true
                
                let usernameLabel = UILabel()
                self.examineScrollView.addSubview(usernameLabel)
                usernameLabel.text = "Kullanıcı: \(selectedUsername)"
                usernameLabel.textColor = .black
                usernameLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
                usernameLabel.adjustsFontSizeToFitWidth = true
                
                usernameLabel.translatesAutoresizingMaskIntoConstraints = false
                
                usernameLabel.leadingAnchor.constraint(equalTo: self.examineScrollView.leadingAnchor, constant: 5).isActive = true
                usernameLabel.widthAnchor.constraint(equalTo: self.examineScrollView.widthAnchor, multiplier: 0.4, constant: -5).isActive = true
                usernameLabel.topAnchor.constraint(equalTo: self.examineScrollView.topAnchor, constant: 5).isActive = true
                usernameLabel.bottomAnchor.constraint(equalTo: self.examineStackView.topAnchor, constant: -5).isActive = true
                
                let completionLabel = UILabel()
                self.examineScrollView.addSubview(completionLabel)
                completionLabel.text = "\(awardsReceived.count)/\(SetAssigner.categories.count * 4)"
                completionLabel.textColor = .black
                completionLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular)
                completionLabel.adjustsFontSizeToFitWidth = true
                
                completionLabel.translatesAutoresizingMaskIntoConstraints = false
                
                completionLabel.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 5).isActive = true
                completionLabel.widthAnchor.constraint(equalTo: self.examineScrollView.widthAnchor, multiplier: 0.2, constant: -5).isActive = true
                completionLabel.topAnchor.constraint(equalTo: self.examineScrollView.topAnchor, constant: 5).isActive = true
                completionLabel.bottomAnchor.constraint(equalTo: self.examineStackView.topAnchor, constant: -5).isActive = true
                
                for award in SetAssigner.awards {
                    
                    // Removes the number and space from the end to get the award's category
                    var awardCategory = award
                    while (awardCategory.last != " ") {
                        awardCategory.removeLast()
                    }
                    awardCategory.removeLast()
                    
                    let awardView = UIView()
                    if awardsReceived.contains(award) {
                        awardView.backgroundColor = .white
                    }
                    else {
                        awardView.backgroundColor = .lightGray
                    }
                    self.examineStackView.addArrangedSubview(awardView)
                    
                    awardView.heightAnchor.constraint(equalToConstant: 100).isActive = true
                    awardView.widthAnchor.constraint(equalTo: self.examineStackView.widthAnchor).isActive = true
                    
                    awardView.translatesAutoresizingMaskIntoConstraints = false
                    
                    let awardImageFrame = UIView()
                    awardView.addSubview(awardImageFrame)
                    
                    awardImageFrame.leadingAnchor.constraint(equalTo: awardView.leadingAnchor, constant: 5).isActive = true
                    awardImageFrame.topAnchor.constraint(equalTo: awardView.topAnchor, constant: 20).isActive = true
                    awardImageFrame.widthAnchor.constraint(equalTo: awardView.widthAnchor, multiplier: 0.2, constant: -20).isActive = true
                    awardImageFrame.bottomAnchor.constraint(equalTo: awardView.bottomAnchor, constant: -20).isActive = true
                    
                    awardImageFrame.translatesAutoresizingMaskIntoConstraints = false
                    
                    awardImageFrame.backgroundColor = .black
                    
                    let awardImage = UIView()
                    awardView.addSubview(awardImage)
                    
                    awardImage.leadingAnchor.constraint(equalTo: awardView.leadingAnchor, constant: 7).isActive = true
                    awardImage.topAnchor.constraint(equalTo: awardView.topAnchor, constant: 22).isActive = true
                    awardImage.widthAnchor.constraint(equalTo: awardView.widthAnchor, multiplier: 0.2, constant: -24).isActive = true
                    awardImage.bottomAnchor.constraint(equalTo: awardView.bottomAnchor, constant: -22).isActive = true
                    
                    awardImage.translatesAutoresizingMaskIntoConstraints = false
                    
                    // Contains all the award colors that can  be assigned to any particular category
                    switch SetAssigner.awardColors[awardCategory] {
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
                    
                    if awardsReceived.contains(award) == false {
                        awardImage.backgroundColor = .gray
                    }

                    let awardNumber = UILabel()
                    awardImage.addSubview(awardNumber)
                    
                    awardNumber.topAnchor.constraint(equalTo: awardImage.topAnchor, constant: 10).isActive = true
                    awardNumber.heightAnchor.constraint(equalTo: awardImage.heightAnchor, constant: -20).isActive = true
                    awardNumber.leftAnchor.constraint(equalTo: awardImage.leftAnchor, constant: 10).isActive = true
                    awardNumber.rightAnchor.constraint(equalTo: awardImage.rightAnchor, constant: -10).isActive = true
                    
                    awardNumber.translatesAutoresizingMaskIntoConstraints = false
                    
                    awardNumber.adjustsFontSizeToFitWidth = true
                    awardNumber.font = UIFont(name: "Times New Roman", size: 30)
                    awardNumber.textAlignment = .center

                    // Gets the award number
                    var awardNumeral = award
                    while awardNumeral.first != "I"
                    {
                        awardNumeral.removeFirst()
                    }
                    awardNumber.text = awardNumeral
                    
                    let awardLabel = UILabel()
                    awardView.addSubview(awardLabel)
                    awardLabel.text = award
                    awardLabel.font = UIFont.systemFont(ofSize: 20, weight: .heavy)
                    awardLabel.textColor = .black
                    awardLabel.adjustsFontSizeToFitWidth = true
                    awardLabel.numberOfLines = 2

                    awardLabel.translatesAutoresizingMaskIntoConstraints = false

                    awardLabel.leadingAnchor.constraint(equalTo: awardImage.trailingAnchor, constant: 5).isActive = true
                    awardLabel.widthAnchor.constraint(equalTo: awardView.widthAnchor, multiplier: 0.3, constant: -5).isActive = true
                    awardLabel.topAnchor.constraint(equalTo: awardView.topAnchor, constant: 5).isActive = true
                    awardLabel.bottomAnchor.constraint(equalTo: awardView.bottomAnchor, constant: -5).isActive = true
                    
                    let awardDescription = UILabel()
                    awardView.addSubview(awardDescription)
                    awardDescription.text = SetAssigner.awardDescriptions[award]
                    awardDescription.font = UIFont.systemFont(ofSize: 15, weight: .regular)
                    awardDescription.textColor = .black
                    awardDescription.adjustsFontSizeToFitWidth = true
                    awardDescription.numberOfLines = 5

                    awardDescription.translatesAutoresizingMaskIntoConstraints = false

                    awardDescription.widthAnchor.constraint(equalTo: awardView.widthAnchor, multiplier: 0.5, constant: -15).isActive = true
                    awardDescription.trailingAnchor.constraint(equalTo: awardView.trailingAnchor, constant: -5).isActive = true
                    awardDescription.topAnchor.constraint(equalTo: awardView.topAnchor, constant: 10).isActive = true
                    awardDescription.bottomAnchor.constraint(equalTo: awardView.bottomAnchor, constant: -10).isActive = true
                

                }
                self.loadingView.removeFromSuperview()
            }
        }
        
        
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
    
    func enableUserInteraction() {
        
        scrollView.isUserInteractionEnabled = true
        pickerView.isUserInteractionEnabled = true
        
    }
    
    func disableUserInteraction() {
        
        scrollView.isUserInteractionEnabled = false
        pickerView.isUserInteractionEnabled = false
        
    }
    
    @IBAction func returnFromExamine(sender: UIButton) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        examineStackView.removeFromSuperview()
        examineScrollView.removeFromSuperview()
        enableUserInteraction()

    }
    
    func addErrorView(examineButtonPressed: Bool) {
           
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
            if examineButtonPressed == false {
                retryButton.setTitle("Tekrar dene", for: .normal)
            }
            else {
                retryButton.setTitle("Geri dön", for: .normal)
            }
           retryButton.titleLabel?.textAlignment = .center
           retryButton.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .regular)
           retryButton.setTitleColor(.systemBlue, for: .normal)
           
           retryButton.addTarget(self, action: #selector(retryButtonPressed), for: .touchUpInside)
           
       }
       
    @IBAction func retryButtonPressed() {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        errorView.removeFromSuperview()
        addLoadingView()
        if retryMethod == "getUserScores" {
            print("Reattempting to get user scores in category *\(retryCategory)*")
            getUserScores(category: retryCategory)
        }
        retryMethod = ""
        retryCategory = ""

    }

}
