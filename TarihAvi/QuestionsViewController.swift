//
//  QuestionsViewController.swift
//  TarihAvi
//
//  Created by Cem Kupeli on 9.04.2020.
//  Copyright © 2020 Cem Kupeli. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import AVFoundation

class QuestionsViewController: UIViewController {
    
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var backgroundImage: UIImageView!
    
    var correctSoundEffect: AVAudioPlayer = AVAudioPlayer()
    let correctSoundFile = Bundle.main.path(forResource: "correct", ofType: ".wav")
    
    var incorrectSoundEffect: AVAudioPlayer = AVAudioPlayer()
    let incorrectSoundFile = Bundle.main.path(forResource: "incorrect", ofType: ".wav")

    // Dismiss in case of results being dismissed
    var resultsDismissed = false {
        willSet {
            view.addSubview(transitionLabel)
    
            transitionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10).isActive = true
            transitionLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -20).isActive = true
            transitionLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 80).isActive = true
            transitionLabel.heightAnchor.constraint(equalToConstant: 70).isActive = true
            
            transitionLabel.translatesAutoresizingMaskIntoConstraints = false
            
            transitionView.isHidden = false
            addLoadingView()
        }
        didSet {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                
                GlobalVariables.currentCategoryVC.adjustCompletion()
                
                self.loadingView.removeFromSuperview()
                self.dismiss(animated: false, completion: nil)
                
            }
        }
    }

    var receivingAnswer = true

    @IBOutlet weak var questionText: UITextView!
    @IBOutlet weak var answer1Text: UIButton!
    @IBOutlet weak var answer2Text: UIButton!
    @IBOutlet weak var answer3Text: UIButton!
    @IBOutlet weak var answer4Text: UIButton!
    @IBOutlet weak var timerText: UILabel!
    @IBOutlet weak var button1: UIButton!
    @IBOutlet weak var button2: UIButton!
    @IBOutlet weak var button3: UIButton!
    @IBOutlet weak var button4: UIButton!
    @IBOutlet weak var questionNumberText: UILabel!
    @IBOutlet weak var lives1: UIImageView!
    @IBOutlet weak var lives2: UIImageView!
    @IBOutlet weak var lives3: UIImageView!
    @IBOutlet weak var lives4: UIImageView!
    
    
    var correctAnswer = 0
    
    @IBOutlet weak var background: UIImageView!
    let loadingView = UIView()
    let errorView = UIView()
    var backView = UIView()
    let transitionView = UIView()
    let transitionLabel = UILabel()
    
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
    
    let database = Firestore.firestore()
    
    var checks = ["receivedUserDataAndUpdatedExposure": false, "receivedSetAndModifier": false, "receivedQuestions": false] {
        didSet {
            if checks == ["receivedUserDataAndUpdatedExposure": true, "receivedSetAndModifier": true, "receivedQuestions": true] {
                print("Checks completed, starting game.")
                loadingView.removeFromSuperview()
                enableUserInteraction()
                updateQuestion()
                timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(gameTimer), userInfo: nil, repeats: true)
                returnButton.isUserInteractionEnabled = true
            }
        }
    }
    
    var currentQuestionIndex = -1
    // The following arrays store all properties of all the questions in the same order
    var questionTexts: [String] = []
    var answer1Texts: [String] = []
    var answer2Texts: [String] = []
    var answer3Texts: [String] = []
    var answer4Texts: [String] = []
    // In order to distinguish it from the property recording the number of correct answers the user gives, this array is named correctAnswersArray
    var correctAnswersArray: [Int] = []
    
    var correctAnswers = 0
    var incorrectAnswers = 0
    var currentGameScore = 0
    var currentSetAndModifier: [String] = [] {
        didSet {
            print("Received current set and modifier: \(currentSetAndModifier)")
            checks["receivedSetAndModifier"] = true
            // After the current set is determined, the user's exposure and success data for that set is received, the exposure data is updated, and the questions for that set is received
            receiveUserDataAndUpdateExposure()
            receiveQuestions()
        }
    }
    var difficultyModifier = 1.0
    
    var timer: Timer?
    var currentGameTime = 100
    var stopTimer = false {
        didSet {
            if stopTimer == true {
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    var currentSetExposure = 0
    var currentSetSuccess = false
    
    override func viewDidLoad() {
        
        returnButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        lives1.image = UIImage(named: "heartFilled")
        lives2.image = UIImage(named: "heartFilled")
        lives3.image = UIImage(named: "heartFilled")
        lives4.image = UIImage(named: "heartFilled")
        questionNumberText.text = "Soru: 1/8"
        
        returnButton.isUserInteractionEnabled = false
        do {
            try correctSoundEffect = AVAudioPlayer(contentsOf: URL(fileURLWithPath: correctSoundFile!))
        }
        catch {
            print(error)
        }
        
        do {
            try incorrectSoundEffect = AVAudioPlayer(contentsOf: URL(fileURLWithPath: incorrectSoundFile!))
        }
        catch {
            print(error)
        }
        
        // Adjusts the difficulty modifier
        switch GlobalVariables.selectedDifficulty {
        case "easy":
            difficultyModifier = 1.0
        case "normal":
            difficultyModifier = 1.2
        case "hard":
            difficultyModifier = 1.5
        default:
            difficultyModifier = 1.0
        }
        
        backgroundImage.isHidden = false
        // Sets the background image
        switch GlobalVariables.categoryName {
        case "Birinci Dünya Savaşı":
            backgroundImage.image = UIImage(named: "WW1")
        case "İkinci Dünya Savaşı":
            backgroundImage.image = UIImage(named: "WW2")
        case "Yakın Türkiye Tarihi":
            backgroundImage.image = UIImage(named: "YTT")
        case "Osmanlı Tarihi":
            backgroundImage.image = UIImage(named: "OT")
        default:
            view.backgroundColor = UIColor(named: "easy")
            backgroundImage.isHidden = true
        }
        
        
        
        GlobalVariables.currentQuestionsVC = self
        currentGameTime = 100
        currentQuestionIndex = -1
        timerText.text = "Kalan süre: \(currentGameTime)"
        disableUserInteraction()
        addLoadingView()
        SetAssigner.pickSet(userID: GlobalVariables.currentUserID, target: self)
        
        view.addSubview(transitionView)
        
        transitionView.isHidden = true
        transitionView.frame = view.frame
        transitionView.backgroundColor = UIColor(named: "4")
        transitionView.translatesAutoresizingMaskIntoConstraints = false
        
        transitionLabel.text = "Tarih Avı"
        transitionLabel.textColor = .black
        transitionLabel.textAlignment = .center
        transitionLabel.font = UIFont.systemFont(ofSize: 50, weight: .regular)
        transitionLabel.adjustsFontSizeToFitWidth = true

        super.viewDidLoad()
    
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        disableUserInteraction()
        let backViewCreator = BackView(target: self)
        backView = backViewCreator.createBackView()
        backViewCreator.yesButton.addTarget(self, action: #selector(leaveGame), for: .touchUpInside)
        backViewCreator.noButton.addTarget(self, action: #selector(stayInGame), for: .touchUpInside)
        
        }
    
    @IBAction func leaveGame(sender: UIButton) {

        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        timer?.invalidate()
        timer = nil
        backView.removeFromSuperview()
        enableUserInteraction()
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func stayInGame(sender: UIButton) {

        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        backView.removeFromSuperview()
        enableUserInteraction()
        
    }
    
    func updateQuestion() {
        
        button1.backgroundColor = .white
        button2.backgroundColor = .white
        button3.backgroundColor = .white
        button4.backgroundColor = .white
        receivingAnswer = true
        currentQuestionIndex += 1
        if (currentQuestionIndex != 8) {
            questionNumberText.text = "Soru: \(currentQuestionIndex + 1)/8"
        }
        
        
        if currentQuestionIndex < 8 && incorrectAnswers < 4 {
            print("Current question index: \(self.currentQuestionIndex)")
            self.questionText.text = questionTexts[currentQuestionIndex]
            self.answer1Text.setTitle(answer1Texts[currentQuestionIndex], for: .normal)
            self.answer2Text.setTitle(answer2Texts[currentQuestionIndex], for: .normal)
            self.answer3Text.setTitle(answer3Texts[currentQuestionIndex], for: .normal)
            self.answer4Text.setTitle(answer4Texts[currentQuestionIndex], for: .normal)
            self.correctAnswer = correctAnswersArray[currentQuestionIndex]
        }
        else {
            determineResult()
        }

    }
    
    @objc func gameTimer() {
        
        currentGameTime -= 1
        timerText.text = "Kalan süre: \(currentGameTime)"
        print(currentGameTime)
        if currentGameTime <= 0 {
            timer?.invalidate()
            timer = nil
            currentGameTime = 0
            determineResult()
        }
        
    }
    
    @IBAction func answer1Pressed(_ sender: Any) {
        
        if receivingAnswer == true {
            receivingAnswer = false
            if correctAnswer == 1 {
                if GlobalVariables.soundEffectsOn == true {
                    correctSoundEffect.play()
                }
                correctAnswers += 1
                button1.backgroundColor = .green
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.updateQuestion()
                }
            }
            else {
                if GlobalVariables.soundEffectsOn == true {
                    incorrectSoundEffect.play()
                }
                incorrectAnswers += 1
                updateLives()
                button1.backgroundColor = .red
                switch correctAnswer {
                    case 2:
                        button2.backgroundColor = .green
                    case 3:
                        button3.backgroundColor = .green
                    case 4:
                        button4.backgroundColor = .green
                    default:
                        print("default")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.updateQuestion()
                }
            }
        }
    }
    
    @IBAction func answer2Pressed(_ sender: Any) {
        
        if receivingAnswer == true {
            receivingAnswer = false
            if correctAnswer == 2 {
                if GlobalVariables.soundEffectsOn == true {
                    correctSoundEffect.play()
                }
                correctAnswers += 1
                button2.backgroundColor = .green
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.updateQuestion()
                }
            }
            else {
                if GlobalVariables.soundEffectsOn == true {
                    incorrectSoundEffect.play()
                }
                incorrectAnswers += 1
                updateLives()
                button2.backgroundColor = .red
                switch correctAnswer {
                    case 1:
                        button1.backgroundColor = .green
                    case 3:
                        button3.backgroundColor = .green
                    case 4:
                        button4.backgroundColor = .green
                    default:
                        print("default")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.updateQuestion()
                }
            }
        }
    }
    
    @IBAction func answer3Pressed(_ sender: Any) {
        
        if receivingAnswer == true {
            receivingAnswer = false
            if correctAnswer == 3 {
                if GlobalVariables.soundEffectsOn == true {
                    correctSoundEffect.play()
                }
                correctAnswers += 1
                button3.backgroundColor = .green
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.updateQuestion()
                }
            }
            else {
                if GlobalVariables.soundEffectsOn == true {
                    incorrectSoundEffect.play()
                }
                incorrectAnswers += 1
                updateLives()
                button3.backgroundColor = .red
                switch correctAnswer {
                    case 1:
                        button1.backgroundColor = .green
                    case 2:
                        button2.backgroundColor = .green
                    case 4:
                        button4.backgroundColor = .green
                    default:
                        print("default")
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.updateQuestion()
                }
            }
        }
    }
    
    @IBAction func answer4Pressed(_ sender: Any) {
        
        if receivingAnswer == true {
            receivingAnswer = false
            if correctAnswer == 4 {
                if GlobalVariables.soundEffectsOn == true {
                    correctSoundEffect.play()
                }
                correctAnswers += 1
                button4.backgroundColor = .green
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.updateQuestion()
                }
            }
            else {
                if GlobalVariables.soundEffectsOn == true {
                    incorrectSoundEffect.play()
                }
                incorrectAnswers += 1
                updateLives()
                button4.backgroundColor = .red
                switch correctAnswer {
                    case 1:
                        button1.backgroundColor = .green
                    case 2:
                        button2.backgroundColor = .green
                    case 3:
                        button3.backgroundColor = .green
                    default:
                        print("default")
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.updateQuestion()
                }
            }
        }
    }
    
    func determineResult() {
        
        let remainingGameTime = currentGameTime
        stopTimer = true
        GlobalVariables.correctAnswers = correctAnswers
        GlobalVariables.incorrectAnswers = incorrectAnswers
        
        if incorrectAnswers == 4 || currentGameTime == 0 {
            currentGameScore = 0
            GlobalVariables.gameScore = currentGameScore
            self.performSegue(withIdentifier: "resultsSegue", sender: self)
        }
        else {
            // update current set's success for this user
            currentSetSuccess = true
            database.collection("users").document(GlobalVariables.currentUserID).collection(GlobalVariables.categoryName).document("\(GlobalVariables.selectedDifficulty)Questions").updateData([
                "\(currentSetAndModifier[0])_success" : currentSetSuccess
            ])
            print("Updated success")
            
            currentGameScore = Int(100.0 * Double(correctAnswers) * difficultyModifier)
            currentGameScore += Int(Double(remainingGameTime) * 1.5)
            
            if correctAnswers == 8 {
                currentGameScore += 50
                print(currentGameScore)
            }
    
            if currentSetAndModifier[1] == "half" {
                // If the user has successfully completed this set before, the score is halved
                currentGameScore = Int(Double(currentGameScore) * 0.5)
            }
            
            GlobalVariables.gameScore = currentGameScore
            self.performSegue(withIdentifier: "resultsSegue", sender: self)
            
        }
    
    }
    // Receives the current set's exposure and success for this user and increases the user's exposure to this set by one in the database
    func receiveUserDataAndUpdateExposure() {
        
        database.collection("users").document(GlobalVariables.currentUserID).collection(GlobalVariables.categoryName).document("\(GlobalVariables.selectedDifficulty)Questions").getDocument { (DocumentSnapshot, error) in
            if error != nil {
                print(error ?? "error")
                self.encounteredError = true
            }
            else {
                self.currentSetExposure = DocumentSnapshot!["\(self.currentSetAndModifier[0])_exposure"] as! Int
                self.currentSetSuccess = DocumentSnapshot!["\(self.currentSetAndModifier[0])_success"] as! Bool

                // Update current set's exposure for this user
                print("Current set exposure: \(self.currentSetExposure)")
                print("Current set success: \(self.currentSetSuccess)")
                self.currentSetExposure += 1
                self.database.collection("users").document(GlobalVariables.currentUserID).collection(GlobalVariables.categoryName).document("\(GlobalVariables.selectedDifficulty)Questions").updateData([
                    "\(self.currentSetAndModifier[0])_exposure" : self.currentSetExposure
                ])
                print("Updated user's exposure to this set")
                self.checks["receivedUserDataAndUpdatedExposure"] = true
            }
        }
        
    }
    
    func receiveQuestions() {
        
        database.collection("\(GlobalVariables.selectedDifficulty)Questions").document(GlobalVariables.categoryName).collection(currentSetAndModifier[0]).getDocuments { (querySnapshot, error) in
            if error != nil {
                print(error ?? "error")
                print("Couldn't receive questions from the database")
                self.encounteredError = true
            }
            else {
                print("Successfully received question from database")
                for number in 0...7 {
                    self.questionTexts.append(querySnapshot!.documents[number]["questionText"] as! String)
                    self.answer1Texts.append(querySnapshot!.documents[number]["answer1"] as! String)
                    self.answer2Texts.append(querySnapshot!.documents[number]["answer2"] as! String)
                    self.answer3Texts.append(querySnapshot!.documents[number]["answer3"] as! String)
                    self.answer4Texts.append(querySnapshot!.documents[number]["answer4"] as! String)
                    self.correctAnswersArray.append(querySnapshot!.documents[number]["correctAnswer"] as! Int)
                }
                self.checks["receivedQuestions"] = true
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
    
    func enableUserInteraction() {
        
        button1.isUserInteractionEnabled = true
        button2.isUserInteractionEnabled = true
        button3.isUserInteractionEnabled = true
        button4.isUserInteractionEnabled = true
        
    }
    
    func disableUserInteraction() {
        
        button1.isUserInteractionEnabled = false
        button2.isUserInteractionEnabled = false
        button3.isUserInteractionEnabled = false
        button4.isUserInteractionEnabled = false
        
    }
    
    func updateLives() {
        
        switch incorrectAnswers {
            case 0:
                lives1.image = UIImage(named: "heartFilled")
                lives2.image = UIImage(named: "heartFilled")
                lives3.image = UIImage(named: "heartFilled")
                lives4.image = UIImage(named: "heartFilled")
            case 1:
                lives1.image = UIImage(named: "heartFilled")
                lives2.image = UIImage(named: "heartFilled")
                lives3.image = UIImage(named: "heartFilled")
                lives4.image = UIImage(named: "heartEmpty")
            case 2:
                lives1.image = UIImage(named: "heartFilled")
                lives2.image = UIImage(named: "heartFilled")
                lives3.image = UIImage(named: "heartEmpty")
                lives4.image = UIImage(named: "heartEmpty")
            case 3:
                lives1.image = UIImage(named: "heartFilled")
                lives2.image = UIImage(named: "heartEmpty")
                lives3.image = UIImage(named: "heartEmpty")
                lives4.image = UIImage(named: "heartEmpty")
            case 4:
                lives1.image = UIImage(named: "heartEmpty")
                lives2.image = UIImage(named: "heartEmpty")
                lives3.image = UIImage(named: "heartEmpty")
                lives4.image = UIImage(named: "heartEmpty")
            default:
                lives1.image = UIImage(named: "heartFilled")
                lives2.image = UIImage(named: "heartFilled")
                lives3.image = UIImage(named: "heartFilled")
                lives4.image = UIImage(named: "heartFilled")
        }
        
    }

    override var prefersStatusBarHidden: Bool {
           return true
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
            SetAssigner.pickSet(userID: GlobalVariables.currentUserID, target: self)
             
         }
    
    
}
