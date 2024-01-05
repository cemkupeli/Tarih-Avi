//
//  CategorySelectionViewController.swift
//  TarihAvi
//
//  Created by Cem Kupeli on 8.04.2020.
//  Copyright © 2020 Cem Kupeli. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth

class CategorySelectionViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var categoryPickerView: UIPickerView!
    @IBOutlet weak var selectedCategoryText: UILabel!
    @IBOutlet weak var difficultySetting: UISegmentedControl!
    @IBOutlet weak var completionBar: UIProgressView!
    @IBOutlet weak var completionPercent: UILabel!
    @IBOutlet weak var returnButton: UIButton!
    @IBOutlet weak var startButton: UIButton!
    
    var completionPercentage: Float = 0.0
    var completionDataReceived = false {
        didSet {
            if completionDataReceived == true {
                completionBar.progress = completionPercentage
                completionPercent.text = "%\(Int(completionPercentage * 100))"
                
                completionDataReceived = false
            }
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        return SetAssigner.activeCategories.count
        
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        label.text = SetAssigner.activeCategories[row]
        label.textColor = .black
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 25, weight: .bold)
        view.addSubview(label)
        
        return view
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        selectedCategoryText.text = SetAssigner.activeCategories[row]
        GlobalVariables.categoryName = SetAssigner.activeCategories[row]
        GlobalVariables.categoryIndex = row
        
        adjustCompletion()
        
    }
    
    override func viewDidLoad() {
        
        returnButton.titleLabel?.adjustsFontSizeToFitWidth = true
        startButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        GlobalVariables.currentCategoryVC = self
        
        categoryPickerView.delegate = self
        categoryPickerView.dataSource = self
    
        self.categoryPickerView.reloadAllComponents()
        
        GlobalVariables.categoryIndex = 0
        self.categoryPickerView.selectRow(GlobalVariables.categoryIndex, inComponent: 0, animated: true)
        GlobalVariables.categoryName = SetAssigner.activeCategories[GlobalVariables.categoryIndex]
        self.selectedCategoryText.text = SetAssigner.activeCategories[GlobalVariables.categoryIndex]
        GlobalVariables.selectedDifficulty = "easy"
        
        adjustCompletion()
        
        super.viewDidLoad()
        
    }
    
    override var prefersStatusBarHidden: Bool {
           return true
       }
    
    @IBAction func beginPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
    
        performSegue(withIdentifier: "questionsSegue", sender: self)
    
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        
        if GlobalVariables.soundEffectsOn == true {
            GlobalVariables.soundEffect.play()
        }
        self.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func difficultyChanged(_ sender: Any) {
        
        if difficultySetting.selectedSegmentIndex == 0 {
            GlobalVariables.selectedDifficulty = "easy"
        }
        else if difficultySetting.selectedSegmentIndex == 1 {
            GlobalVariables.selectedDifficulty = "normal"
        }
        else if difficultySetting.selectedSegmentIndex == 2 {
            GlobalVariables.selectedDifficulty = "hard"
        }
        
        adjustCompletion()
        
    }
    
    // Adjusts the completion percentage and progress bar for the current category and selected difficulty
    func adjustCompletion() {
        
        let database = Firestore.firestore()
        
        let setDataRef = database.collection("users").document(GlobalVariables.currentUserID).collection(GlobalVariables.categoryName).document("\(GlobalVariables.selectedDifficulty)Questions")
        
        setDataRef.getDocument { (DocumentSnapshot, error) in
            
            let numSets = DocumentSnapshot!["numberOfSets"] as! Int
            var numSuccess = 0
            
            for number in 1...numSets {
                
                if (DocumentSnapshot!["set\(number)_success"] as! Bool) == true {
                    numSuccess += 1
                }
                
            }
            
            if numSuccess == numSets {
                self.completionPercentage = 1.0
            }
            else {
                self.completionPercentage =  Float(numSuccess) / Float(numSets)
            }
            
            print("Completion percentage: \(self.completionPercentage)") // for testing
            self.completionDataReceived = true
            
        }

        
    }
    
}
