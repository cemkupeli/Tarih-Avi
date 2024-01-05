//
//  GlobalVariables.swift
//  TarihAvi
//
//  Created by Cem Kupeli on 8.04.2020.
//  Copyright © 2020 Cem Kupeli. All rights reserved.
//

import Foundation
import AVFoundation

class GlobalVariables {
    
    static var soundEffectsOn = true;
    
    static var soundEffect: AVAudioPlayer = AVAudioPlayer()
    static let soundFile = Bundle.main.path(forResource: "correct", ofType: ".wav")
    
    static var userEmail = "userEmail";
    static var userUsername = "userUsername";
    static var userIsAdmin = false
    
    static var currentUserID = ""
    
    static var categoryName = "";
    static var categoryID = "";
    static var categoryIndex = 0;
    static var selectedDifficulty = ""

    static var currentCategoryVC: CategorySelectionViewController = CategorySelectionViewController()
    static var currentQuestionsVC: QuestionsViewController = QuestionsViewController()
    static var gameScore = 0
    static var correctAnswers = 0
    static var incorrectAnswers = 0
    
    static var numberOfUsers = 0
    static var numberOfAwards = 0
}
