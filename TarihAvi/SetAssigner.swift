//
//  SetAssigner.swift
//  TarihAvi
//
//  Created by Cem Kupeli on 15.04.2020.
//  Copyright © 2020 Cem Kupeli. All rights reserved.
//

import Foundation
import Firebase
import FirebaseAuth

class SetAssigner {
    
    static var currentSet = ""
    static var categories: [String] = []
    static var activeCategories: [String] = []
    static var awards: [String] = []
    static var awardDescriptions: [String:String] = [:]
    static var awardColors: [String:String] = [:]
    
    static func getCategories(target: LoginViewController) {
        
        categories = []
        let database = Firestore.firestore()
        database.collection("categories").getDocuments { (QuerySnapshot, error) in
        if error != nil {
            print(error ?? "error")
            target.encounteredError = true
        }
        else {
            print("Categories received")
            for document in QuerySnapshot!.documents {
                categories.append((document["category_name"] as! String))
                }
            print("Categories: \(categories)")
            target.checks["categoriesReceived"] = true
            print("Login checks: \(target.checks)")
            }
        }
        
    }
    
    static func getActiveCategories(target: HomeViewController) {
        
        activeCategories = []
        let database = Firestore.firestore()
        database.collection("categories").getDocuments { (QuerySnapshot, error) in
        if error != nil {
            print(error ?? "error")
            print("1")
        }
        else {
            print("Active categories received")
            for document in QuerySnapshot!.documents {
                if (document["isActive"] as! Bool) == true {
                activeCategories.append((document["category_name"] as! String))
                }
            }
            print("Active categories: \(activeCategories)")
            target.checks["activeCategoriesReceived"] = true
            print("Home checks: \(target.checks)")
            }
        }
        
    }
    // Gets the current awards and the award color associated with each category
    static func getAwards(target: LoginViewController) {
        
        awards = []
        awardColors = [:]
        let database = Firestore.firestore()
        database.collection("awards").document("awardDetails").getDocument { (DocumentSnapshot, error) in
            if error != nil {
                print(error ?? "error")
                target.encounteredError = true
            }
            else {
                print("Awards received")
                awards = DocumentSnapshot!["awardNames"] as! [String]
                print("Current awards: \(awards)")
                for category in categories {
                    awardColors[category] = (DocumentSnapshot!["\(category)_awardColor"] as! String)
                }
                print("Award colors: \(awardColors)")
                target.checks["awardsReceived"] = true
            }
        }
        
    }

    static func getAwardDescriptions(target: HomeViewController) {
        
        awardDescriptions = [:]
        let database = Firestore.firestore()
        database.collection("awards").document("awardDescriptions").getDocument { (DocumentSnapshot, error) in
            if error != nil {
                print(error ?? "error")
            }
            else {
                
                for award in SetAssigner.awards {
                    
                    awardDescriptions[award] = (DocumentSnapshot![award] as! String)
                    
                }
                target.checks["awardDescriptionsReceived"] = true
                print("Award descriptions received, home checks: \(target.checks)")
                
            }
        }
        
    }
    
    static func pickSet(userID: String, target: QuestionsViewController) {
        
        let database = Firestore.firestore()
        let chosenCategory = GlobalVariables.categoryName
        let chosenDifficulty = GlobalVariables.selectedDifficulty
        var scoreModifier = "normal"
        var nextSet = "" {
            didSet {
                if !(nextSet.isEmpty) {
                    currentSet = nextSet
                    target.currentSetAndModifier = [nextSet, scoreModifier]
                }
            }
        }
        var setNumber = 0 {
            didSet {
                database.collection("users").document(userID).collection(chosenCategory).document("\(chosenDifficulty)Questions").getDocument { (DocumentSnapshot, error) in
                        
                        if error != nil {
                            print(error ?? "error")
                            target.encounteredError = true
                        }
                        else {
                            
                            for number in 1...setNumber {
                                
                                if (DocumentSnapshot!["set\(number)_exposure"] as! Int) == 0 {
                
                                    scoreModifier = "normal"
                                    nextSet = "set\(number)"
                                    break
                                }
                            }
                            
                            
                            if nextSet.isEmpty {
                                
                                print("User has been exposed to all sets at least once")
                                var currentSetExposure = 10000000
                                var currentSet = ""
                                for number in 1...setNumber {
                                        
                                    if (DocumentSnapshot!["set\(number)_success"] as! Bool) == false {
                                        
                                        if (DocumentSnapshot!["set\(number)_exposure"] as! Int) < currentSetExposure {
                                            currentSetExposure = (DocumentSnapshot!["set\(number)_exposure"] as! Int)
                                            currentSet = "set\(number)"
                                            print("Among the unsuccesful sets, the set that the user has been exposed to least is *\(currentSet)*")
                                        }
                                
                                    }
                                    
                                }
                                scoreModifier = "normal"
                                nextSet = currentSet
                                    
                            }
                            
                            if nextSet.isEmpty {
                                
                                print("The user has successfully completed each set")
                                var currentSetExposure = 10000000
                                var currentSet = ""
                                for number in 1...setNumber {
                                        
                                    if (DocumentSnapshot!["set\(number)_exposure"] as! Int) < currentSetExposure {
                                        currentSetExposure = (DocumentSnapshot!["set\(number)_exposure"] as! Int)
                                        currentSet = "set\(number)"
                                    }

                                }
                                print("The set that the user has been exposed to least is *\(currentSet)*")
                                scoreModifier = "half"
                                nextSet = currentSet
                            }
                        }
                        
                    }
            }
        }
        
        let setDataRef = database.collection("setData").document("\(chosenDifficulty)Questions")
        
        setDataRef.getDocument { (DocumentSnapshot, error) in
            if error != nil {
                print(error ?? "error")
                target.encounteredError = true
            }
            else {
                setNumber = (DocumentSnapshot!["\(chosenCategory)_setNumber"] as! Int)
                print("Total sets: \(setNumber)")
            }
        }
    }
    // for either adding set data to a newly registered user or adding set data for a new category (has two versions for the two different view controller types it may be called by
    static func addSetDataToUser(currentCategories: [String], userID: String, target: SignupViewController) {
        
        var easyCategorySets: [String:Int] = [:]
        var normalCategorySets: [String:Int] = [:]
        var hardCategorySets: [String:Int] = [:]
    
        var dictionariesCompleted = 0 {
            didSet {
                if dictionariesCompleted == 3 {
                    for categoryName in currentCategories {
                        
                        let easyCategorySets: Int = easyCategorySets[categoryName]!
                        
                        database.collection("users").document(userID).collection(categoryName).document("easyQuestions").setData([
                            "set1_exposure" : 0,
                            "set1_success" : false
                        ])
                        
                        database.collection("users").document(userID).collection(categoryName).document("easyQuestions").updateData([
                            "numberOfSets" : easyCategorySets
                        ])
                        
                        for number in 2...easyCategorySets {
                            
                            database.collection("users").document(userID).collection(categoryName).document("easyQuestions").updateData([
                                "set\(number)_exposure" : 0,
                                "set\(number)_success" : false
                            ])
                            
                        }
                        
                        let normalCategorySets: Int = normalCategorySets[categoryName]!
                        database.collection("users").document(userID).collection(categoryName).document("normalQuestions").setData([
                            "set1_exposure" : 0,
                            "set1_success" : false
                        ])
                        
                        database.collection("users").document(userID).collection(categoryName).document("normalQuestions").updateData([
                            "numberOfSets" : normalCategorySets
                        ])
                        
                        for number in 2...normalCategorySets {
                            
                            database.collection("users").document(userID).collection(categoryName).document("normalQuestions").updateData([
                                "set\(number)_exposure" : 0,
                                "set\(number)_success" : false
                            ])
                            
                        }
                        
                        let hardCategorySets: Int = hardCategorySets[categoryName]!
                        database.collection("users").document(userID).collection(categoryName).document("hardQuestions").setData([
                            "set1_exposure" : 0,
                            "set1_success" : false
                        ])
                        
                        database.collection("users").document(userID).collection(categoryName).document("hardQuestions").updateData([
                            "numberOfSets" : hardCategorySets
                        ])
                        
                        for number in 2...hardCategorySets {
                            
                            database.collection("users").document(userID).collection(categoryName).document("hardQuestions").updateData([
                                "set\(number)_exposure" : 0,
                                "set\(number)_success" : false
                            ])
                            
                        }
                        
                        target.setDataAdded = true
                    }
                }
            }
        }
        let database = Firestore.firestore()
        
        
        database.collection("setData").document("easyQuestions").getDocument { (DocumentSnapshot, error) in

            if error != nil {
                print(error ?? "error")
                print("2")
            }
            else {
            print("Easy questions received")
            for categoryName in currentCategories {

                easyCategorySets[categoryName] = (DocumentSnapshot!["\(categoryName)_setNumber"] as! Int)

            }
            print(easyCategorySets)
            dictionariesCompleted += 1
            }
        }
        database.collection("setData").document("normalQuestions").getDocument { (DocumentSnapshot, error) in

            if error != nil {
                print(error ?? "error")
                print("3")
            }
            else {
            print("Normal questions received")
                for categoryName in currentCategories {

                    normalCategorySets[categoryName] = (DocumentSnapshot!["\(categoryName)_setNumber"] as! Int)

                }
            print(normalCategorySets)
            dictionariesCompleted += 1
            }
        }
        database.collection("setData").document("hardQuestions").getDocument { (DocumentSnapshot, error) in

            if error != nil {
                print(error ?? "error")
                print("4")
            }
            else {
            print("Hard questions received")
            for categoryName in currentCategories {

                hardCategorySets[categoryName] = (DocumentSnapshot!["\(categoryName)_setNumber"] as! Int)

            }
            print(hardCategorySets)
            dictionariesCompleted += 1
            }
        }
        
        for categoryName in currentCategories {
            
            database.collection("users").document(userID).collection("scores").document(categoryName).setData([
                "userScore" : 0
            ])
        }
        // Adds award data to user
        database.collection("users").document(userID).collection("scores").document("totalScore").setData(["userScore" : 0])
        
        database.collection("users").document(userID).collection("awards").document("userAwards").setData(["awardsRegistered" : awards.count, "awardsReceived" : 0])
    
        for award in awards {
        
            database.collection("users").document(userID).collection("awards").document("userAwards").updateData([award : false])
        
        }
    
    }
    
    static func addSetDataToUser(currentCategories: [String], userID: String, target: HomeViewController) {
           
           var easyCategorySets: [String:Int] = [:]
           var normalCategorySets: [String:Int] = [:]
           var hardCategorySets: [String:Int] = [:]
       
           var dictionariesCompleted = 0 {
               didSet {
                   if dictionariesCompleted == 3 {
                       for categoryName in currentCategories {
                           
                           let easyCategorySets: Int = easyCategorySets[categoryName]!
                           
                           database.collection("users").document(userID).collection(categoryName).document("easyQuestions").setData([
                               "set1_exposure" : 0,
                               "set1_success" : false
                           ])
                           
                           database.collection("users").document(userID).collection(categoryName).document("easyQuestions").updateData([
                               "numberOfSets" : easyCategorySets
                           ])
                           
                           for number in 2...easyCategorySets {
                               
                               database.collection("users").document(userID).collection(categoryName).document("easyQuestions").updateData([
                                   "set\(number)_exposure" : 0,
                                   "set\(number)_success" : false
                               ])
                               
                           }
                           
                           let normalCategorySets: Int = normalCategorySets[categoryName]!
                           database.collection("users").document(userID).collection(categoryName).document("normalQuestions").setData([
                               "set1_exposure" : 0,
                               "set1_success" : false
                           ])
                           
                           database.collection("users").document(userID).collection(categoryName).document("normalQuestions").updateData([
                               "numberOfSets" : normalCategorySets
                           ])
                           
                           for number in 2...normalCategorySets {
                               
                               database.collection("users").document(userID).collection(categoryName).document("normalQuestions").updateData([
                                   "set\(number)_exposure" : 0,
                                   "set\(number)_success" : false
                               ])
                               
                           }
                           
                           let hardCategorySets: Int = hardCategorySets[categoryName]!
                           database.collection("users").document(userID).collection(categoryName).document("hardQuestions").setData([
                               "set1_exposure" : 0,
                               "set1_success" : false
                           ])
                           
                           database.collection("users").document(userID).collection(categoryName).document("hardQuestions").updateData([
                               "numberOfSets" : hardCategorySets
                           ])
                           
                           for number in 2...hardCategorySets {
                               
                               database.collection("users").document(userID).collection(categoryName).document("hardQuestions").updateData([
                                   "set\(number)_exposure" : 0,
                                   "set\(number)_success" : false
                               ])
                               
                           }
                        
                        // Increments the recorded categories
                        database.collection("users").document(userID).getDocument { (DocumentSnapshot, error) in
                            if error != nil {
                                print(error ?? "error")
                                target.encounteredError = true
                            }
                            else {
                                let currentRecordedCategories = (DocumentSnapshot!["recordedCategories"] as! Int)
                                
                                database.collection("users").document(userID).updateData([
                                    "recordedCategories" : currentRecordedCategories + 1
                                ])
                            }
                        }

                        target.expectedNewCategories -= 1
                       }
                   }
               }
           }
           let database = Firestore.firestore()
           
           
           database.collection("setData").document("easyQuestions").getDocument { (DocumentSnapshot, error) in

               if error != nil {
                   print(error ?? "error")
                   target.encounteredError = true
               }
               else {
               print("Easy questions received")
               for categoryName in currentCategories {

                   easyCategorySets[categoryName] = (DocumentSnapshot!["\(categoryName)_setNumber"] as! Int)

               }
               print(easyCategorySets)
               dictionariesCompleted += 1
               }
           }
           database.collection("setData").document("normalQuestions").getDocument { (DocumentSnapshot, error) in

               if error != nil {
                   print(error ?? "error")
                   target.encounteredError = true
               }
               else {
               print("Normal questions received")
                   for categoryName in currentCategories {

                       normalCategorySets[categoryName] = (DocumentSnapshot!["\(categoryName)_setNumber"] as! Int)

                   }
               print(normalCategorySets)
               dictionariesCompleted += 1
               }
           }
           database.collection("setData").document("hardQuestions").getDocument { (DocumentSnapshot, error) in

               if error != nil {
                   print(error ?? "error")
                   target.encounteredError = true
               }
               else {
               print("Hard questions received")
               for categoryName in currentCategories {

                   hardCategorySets[categoryName] = (DocumentSnapshot!["\(categoryName)_setNumber"] as! Int)

               }
               print(hardCategorySets)
               dictionariesCompleted += 1
               }
           }
           
           for categoryName in currentCategories {
               
               database.collection("users").document(userID).collection("scores").document(categoryName).setData([
                   "userScore" : 0
               ])
           }
        
       }
    
    // checks for new categories and calls the addSetDataToUser function if there are any, also adds award data for any newly added categories (with the four primary awards that are there for each category)
    static func checkForNewCategoryData(userID: String, target: HomeViewController) {
                
        // Reads the user property "recoredCategories" to have an idea as to whether new categories will be added. If recordedCategories and categories.count are equal, this means that the user is up to speed in terms of category data and the check will be made and the addSetDataToUser method will not be called. However, if there is a positive difference between the two, then the expectedNewCategories property of the current HomeViewController will be set equal to this difference. The addSetDataToUser method (specifically the one with the HomeViewController parameter) will also be called this many times, and each time it will decrease expectedNewCategories by 1. By the time expectedNewCategories reaches zero, the checkForNewCategoryData will also have completed its course (since it only calls the addSetDataToUser function for as many times as the expectedNewCategories property,) and the check will be made.
        var recordedCategories = 0 {
            didSet {
                let newCategories = categories.count - recordedCategories
                if newCategories == 0 {
                    target.checks["categoryDataChecked"] = true
                    print("Checked for new category data, home checks: \(target.checks)")
                }
                else {
                    target.expectedNewCategories = newCategories
                    for categoryName in categories {
                    
                        database.collection("users").document(userID).collection(categoryName).getDocuments { (QuerySnapshot, error) in
                            if error != nil {
                                print(error ?? "error")
                                target.encounteredError = true
                            }
                            else {
                            
                                if QuerySnapshot?.isEmpty == true {
                
                                    print("This user does not have any set data for category *\(categoryName)*")
                                    newCategory = categoryName
                                
                                }
                            
                            }
                        }
                    
                    }
                }
            }
        }

        let database = Firestore.firestore()
        
        // Each time a new category is identified (one that has no documents in it for the current user) the set data for that category is added
        var newCategory = "" {
            didSet {
                addSetDataToUser(currentCategories: [newCategory], userID: GlobalVariables.currentUserID, target: target)
                database.collection("users").document(userID).collection("awards").document("userAwards").getDocument { (DocumentSnapshot, error) in
                    if error != nil {
                        print(error ?? "error")
                        target.encounteredError = true
                    }
                    else {
                        var currentAwardsRegistered = (DocumentSnapshot!["awardsRegistered"] as! Int)
                        currentAwardsRegistered += 4
                        database.collection("users").document(userID).collection("awards").document("userAwards").updateData([
                            "awardsRegistered" : currentAwardsRegistered,
                            "\(newCategory) I" : false,
                            "\(newCategory) II" : false,
                            "\(newCategory) III" : false,
                            "\(newCategory) IV" : false
                        ])
                        print("Added set and award data to user for  category *\(newCategory)*")
                    }
                }
                
            }
        }
        
        database.collection("users").document(userID).getDocument { (DocumentSnapshot, error) in
            if error != nil {
                print(error ?? "error")
                target.encounteredError = true
            }
            else {
                recordedCategories = (DocumentSnapshot!["recordedCategories"] as! Int)
            }
        }
        
    }

    // for adding new set data to the user on a preexistent category
    static func checkForNewSetData(userID: String, target: HomeViewController) {
        
        let database = Firestore.firestore()
        
        // For each difficulty whose check is complete (the part after all three dictionaries are completed,) difficultiesChecked is increased by 1, and the check for the HomeViewController is made when all difficulties are checked (when the property attains the value 3)
        var difficultiesChecked = 0 {
            didSet {
                if difficultiesChecked == 3 * categories.count {
                    target.checks["setDataChecked"] = true
                    print("Checked for new set data, home checks: \(target.checks)")
                }
            }
        }
        
        var easyCategorySets: [String:Int] = [:]
        var normalCategorySets: [String:Int] = [:]
        var hardCategorySets: [String:Int] = [:]
        
        var dictionariesCompleted = 0 {
            didSet {
                if dictionariesCompleted == 3 {
                    for categoryName in categories {

                        database.collection("users").document(userID).collection(categoryName).document("easyQuestions").getDocument { (DocumentSnapshot, error) in
                            if error != nil {
                                print(error ?? "error")
                                target.encounteredError = true
                            }
                            else {
                                
                                let userSets = DocumentSnapshot!["numberOfSets"] as! Int
                                let totalSets = easyCategorySets[categoryName]!
                                
                                if  userSets != totalSets {
                                    print("User has fewer sets recorded in category *\(categoryName)* and difficulty *easy*")
                                    for setNumber in (userSets + 1) ... totalSets {
                                        
                                        database.collection("users").document(userID).collection(categoryName).document("easyQuestions").updateData([
                                            "set\(setNumber)_exposure" : 0,
                                            "set\(setNumber)_success" : false
                                        ])
                                        
                                    }
                                    
                                    database.collection("users").document(userID).collection(categoryName).document("easyQuestions").updateData([
                                        "numberOfSets" : totalSets
                                    ])
                                    
                                }
                                difficultiesChecked += 1
                                
                            }
                        }
                        
                        database.collection("users").document(userID).collection(categoryName).document("normalQuestions").getDocument { (DocumentSnapshot, error) in
                            if error != nil {
                                print(error ?? "error")
                                target.encounteredError = true
                            }
                            else {
                                
                                let userSets = DocumentSnapshot!["numberOfSets"] as! Int
                                let totalSets = normalCategorySets[categoryName]!
                                
                                if  userSets != totalSets {
                                    print("User has fewer sets recorded in category *\(categoryName)* and difficulty *normal*")
                                    for setNumber in (userSets + 1) ... totalSets {
                                        
                                        database.collection("users").document(userID).collection(categoryName).document("normalQuestions").updateData([
                                            "set\(setNumber)_exposure" : 0,
                                            "set\(setNumber)_success" : false
                                        ])
                                        
                                    }
                                    
                                    database.collection("users").document(userID).collection(categoryName).document("normalQuestions").updateData([
                                        "numberOfSets" : totalSets
                                    ])
                                    
                                }
                                difficultiesChecked += 1
                                
                            }
                        }

                        database.collection("users").document(userID).collection(categoryName).document("hardQuestions").getDocument { (DocumentSnapshot, error) in
                            if error != nil {
                                print(error ?? "error")
                                target.encounteredError = true
                            }
                            else {
                                
                                let userSets = DocumentSnapshot!["numberOfSets"] as! Int
                                let totalSets = hardCategorySets[categoryName]!
                                
                                if  userSets != totalSets {
                                    print("User has fewer sets recorded in category *\(categoryName)* and difficulty *hard*")
                                    for setNumber in (userSets + 1) ... totalSets {
                                        
                                        database.collection("users").document(userID).collection(categoryName).document("hardQuestions").updateData([
                                            "set\(setNumber)_exposure" : 0,
                                            "set\(setNumber)_success" : false
                                        ])
                                        
                                    }
                                    
                                    database.collection("users").document(userID).collection(categoryName).document("hardQuestions").updateData([
                                        "numberOfSets" : totalSets
                                    ])
                                    
                                }
                                difficultiesChecked += 1
                            }
                        }

                        
                    
                    }

                }
            }
        }
        
        database.collection("setData").document("easyQuestions").getDocument { (DocumentSnapshot, error) in
            if error != nil {
                print(error ?? "error")
                target.encounteredError = true
            }
            else {
                
                for categoryName in categories {
                    
                    easyCategorySets[categoryName] = (DocumentSnapshot!["\(categoryName)_setNumber"] as! Int)
                    
                }
                dictionariesCompleted += 1
            }
        
        database.collection("setData").document("normalQuestions").getDocument { (DocumentSnapshot, error) in
            if error != nil {
                print(error ?? "error")
                target.encounteredError = true
            }
            else {
                
                for categoryName in categories {
                    
                    normalCategorySets[categoryName] = (DocumentSnapshot!["\(categoryName)_setNumber"] as! Int)
                    
                }
                dictionariesCompleted += 1
            }
        }
        
        database.collection("setData").document("hardQuestions").getDocument { (DocumentSnapshot, error) in
            if error != nil {
                print(error ?? "error")
                target.encounteredError = true
            }
            else {
                
                for categoryName in categories {
                    
                    hardCategorySets[categoryName] = (DocumentSnapshot!["\(categoryName)_setNumber"] as! Int)
                    
                }
                dictionariesCompleted += 1
            }
        }
    
        }
    
    }
    // For adding sets with sample questions to categories (for future editing)
//    for difficulty in ["easy", "normal", "hard"] {
//        let database = Firestore.firestore()
//        let categoryRef = database.collection("\(difficulty)Questions").document(/* Category name */)
//        for setNumber in 1...5 {
//
//            categoryRef.collection("set\(setNumber)").document("question1").setData([
//                "questionText": "sampleQuestion",
//                "answer1": "a1",
//                "answer2": "a2",
//                "answer3": "a3",
//                "answer4": "a4",
//                "correctAnswer": 1
//            ])
//
//            for questionNumber in 2...8 {
//                categoryRef.collection("set\(setNumber)").document("question\(questionNumber)").setData([
//                    "questionText": "sampleQuestion",
//                    "answer1": "a1",
//                    "answer2": "a2",
//                    "answer3": "a3",
//                    "answer4": "a4",
//                    "correctAnswer": 1
//                ])
//            }
//
//        }
//    }
}
