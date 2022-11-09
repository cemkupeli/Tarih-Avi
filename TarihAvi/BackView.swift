//
//  BackView.swift
//  TarihAvi
//
//  Created by Cem Kupeli on 11.04.2020.
//  Copyright © 2020 Cem Kupeli. All rights reserved.
//

import Foundation
import UIKit

class BackView {

    var currentViewController = UIViewController()
    var yesButton = UIButton()
    var noButton = UIButton()
    
    init(target: UIViewController) {
        currentViewController = target
    }
    
    func createBackView() -> UIView {
        
             let backView = UIView()
             currentViewController.view.addSubview(backView)
        
             backView.translatesAutoresizingMaskIntoConstraints = false
        
             let viewWidth = currentViewController.view.frame.width
             backView.leadingAnchor.constraint(equalTo: currentViewController.view.leadingAnchor, constant: viewWidth/2 - 100).isActive = true
             backView.trailingAnchor.constraint(equalTo: currentViewController.view.trailingAnchor, constant: -(viewWidth/2 - 100)).isActive = true
             let viewHeight = currentViewController.view.frame.height
             backView.topAnchor.constraint(equalTo: currentViewController.view.topAnchor, constant: viewHeight/2 - 100).isActive = true
             backView.bottomAnchor.constraint(equalTo: currentViewController.view.bottomAnchor, constant: -(viewHeight/2 - 100)).isActive = true
             backView.backgroundColor = .white
             
    
             let backLabel = UILabel()
             backView.addSubview(backLabel)
        
             backLabel.translatesAutoresizingMaskIntoConstraints = false
        
             backLabel.leadingAnchor.constraint(equalTo: backView.leadingAnchor, constant: 20).isActive = true
             backLabel.trailingAnchor.constraint(equalTo: backView.trailingAnchor, constant: -20).isActive = true
             backLabel.topAnchor.constraint(equalTo: backView.topAnchor).isActive = true
             backLabel.heightAnchor.constraint(equalTo: backView.heightAnchor, multiplier: 2/3).isActive = true
        
             backLabel.text = "Oyundan çıkmak istediğinize emin misiniz?"
             backLabel.numberOfLines = 5
             backLabel.textAlignment = .center
             backLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
             backLabel.adjustsFontSizeToFitWidth = true
         
             backView.addSubview(yesButton)
        
             yesButton.translatesAutoresizingMaskIntoConstraints = false
        
             yesButton.leadingAnchor.constraint(equalTo: backView.leadingAnchor).isActive = true
             yesButton.widthAnchor.constraint(equalTo: backView.widthAnchor, multiplier: 0.5).isActive = true
             yesButton.heightAnchor.constraint(equalTo: backView.heightAnchor, multiplier: 1/3).isActive = true
             yesButton.bottomAnchor.constraint(equalTo: backView.bottomAnchor).isActive = true
        
             yesButton.setTitle("Evet", for: .normal)
             yesButton.titleLabel?.textAlignment = .center
             yesButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .regular)
             yesButton.titleLabel?.textColor = .black
             yesButton.backgroundColor = .lightGray
             yesButton.titleLabel?.adjustsFontSizeToFitWidth = true
             
             backView.addSubview(noButton)
        
             noButton.translatesAutoresizingMaskIntoConstraints = false
        
             noButton.trailingAnchor.constraint(equalTo: backView.trailingAnchor).isActive = true
             noButton.widthAnchor.constraint(equalTo: backView.widthAnchor, multiplier: 0.5).isActive = true
             noButton.heightAnchor.constraint(equalTo: backView.heightAnchor, multiplier: 1/3).isActive = true
             noButton.bottomAnchor.constraint(equalTo: backView.bottomAnchor).isActive = true

             
             noButton.setTitle("Hayır", for: .normal)
             noButton.titleLabel?.textAlignment = .center
             noButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .regular)
             noButton.titleLabel?.textColor = .black
             noButton.backgroundColor = .gray
             noButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        return backView
    }
    
}
