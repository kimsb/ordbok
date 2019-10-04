//
//  CustomUIButton.swift
//  ordbok
//
//  Created by Kim Stephen Bovim on 04/10/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import UIKit

@IBDesignable extension UIButton {

    @IBInspectable var borderWidth: CGFloat {
        set {
            layer.borderWidth = newValue
        }
        get {
            return layer.borderWidth
        }
    }

    @IBInspectable var cornerRadius: CGFloat {
        set {
            layer.cornerRadius = newValue
        }
        get {
            return layer.cornerRadius
        }
    }

    @IBInspectable var borderColor: UIColor? {
        set {
            guard let uiColor = newValue else { return }
            layer.borderColor = uiColor.cgColor
        }
        get {
            guard let color = layer.borderColor else { return nil }
            return UIColor(cgColor: color)
        }
    }
}

class CustomUIButton: UIButton {
    var hasBeenPressed = false
    
    func deselect(parentView: UIView) {
        if (hasBeenPressed) {
            toggle(parentView: parentView)
        }
    }
    
    func toggle(parentView: UIView) {
        if (hasBeenPressed) {
            backgroundColor = parentView.backgroundColor
            setTitleColor(parentView.tintColor, for: .normal)
        } else {
            backgroundColor = parentView.tintColor
            setTitleColor(.white, for: .normal)
        }
        hasBeenPressed = !hasBeenPressed
    }
}
