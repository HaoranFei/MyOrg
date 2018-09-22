//
//  mainButtons.swift
//  MyOrg
//
//  Created by gaojun on 2018/9/16.
//  Copyright © 2018年 spicy chicken. All rights reserved.
//

import UIKit

@IBDesignable class mainButtons: UIStackView {
    //MARK: Properties
    //Called immediately after the property’s value is set
    private var MainPageButtons = [UIButton]()
    var currentState = 0 {
        didSet {
            updateButtonSelectionStates()
        }
    }
    @IBInspectable var buttonSize: CGSize = CGSize(width: 44.0, height: 44.0)
    @IBInspectable var buttonCount: Int = 5
    
    
    
    private func updateButtonSelectionStates() {
        for (index, button) in ratingButtons.enumerated() {
            // If the index of a button is less than the rating, that button should be selected.
            button.isSelected = currentState == index
        }
    }
    

}
