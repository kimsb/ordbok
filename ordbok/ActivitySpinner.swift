//
//  ActivitySpinner.swift
//  ordbok
//
//  Created by Kim Stephen Bovim on 18/10/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import Foundation
import UIKit

class ActivitySpinner: UIVisualEffectView {
    
    static let shared = ActivitySpinner()
    
    private let activityIndictor: UIActivityIndicatorView = UIActivityIndicatorView(style: UIActivityIndicatorView.Style.gray)
    private let label: UILabel = UILabel()
    private let blurEffect = UIBlurEffect(style: .dark)
    private let vibrancyView: UIVisualEffectView
    private var sinceShown = Date()
    private var hideCalled = false
    private var height: CGFloat = 50
    private let width = CGFloat(160)
    private let activityIndicatorSize: CGFloat = 40
    private var refreshControl: UIRefreshControl?
    
    private init() {
        self.vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
        super.init(effect: blurEffect)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(blurEffect: blurEffect))
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        DispatchQueue.main.async(execute: {
            self.contentView.addSubview(self.vibrancyView)
            self.contentView.addSubview(self.activityIndictor)
            self.contentView.addSubview(self.label)
        })
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateFrames()
    }
    
    private func updateFrames() {
        DispatchQueue.main.async(execute: {
            if let superview = self.superview {
                self.frame = CGRect(x: superview.frame.size.width / 2 - self.width / 2,
                                    y: superview.frame.height / 2 - self.height / 2,
                                    width: self.width,
                                    height: self.height)
                self.vibrancyView.frame = self.bounds
                
                self.activityIndictor.frame = CGRect(x: 5,
                                                     y: self.height / 2 - self.activityIndicatorSize / 2,
                                                     width: self.activityIndicatorSize,
                                                     height: self.activityIndicatorSize)
                self.activityIndictor.color = UIColor.lightText
                self.layer.cornerRadius = 8.0
                self.layer.masksToBounds = true
                self.label.textAlignment = NSTextAlignment.center
                self.label.frame = CGRect(x: self.activityIndicatorSize + 5,
                                          y: 0,
                                          width: self.width - self.activityIndicatorSize - 15,
                                          height: self.height)
                self.label.textColor = UIColor.lightText
            }
        })
    }
    
    func show(text: String, holdingViewController: UIViewController) {
        if refreshControl != nil {
            return
        }
        DispatchQueue.main.async(execute: {
            self.label.text = text
            self.height = 50
            self.label.numberOfLines = 1
            self.label.font = UIFont.systemFont(ofSize: 17)
            self.hideCalled = false
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if (!self.hideCalled) {
                self.sinceShown = Date()
                if !self.activityIndictor.isAnimating {
                    //let holdingView = (UIApplication.shared.delegate as! AppDelegate).window!.rootViewController!.view!
                    holdingViewController.view.addSubview(self)
                    self.activityIndictor.startAnimating()
                    self.isHidden = false
                } else {
                    self.updateFrames()
                }
            }
        }
    }
    
    func refreshSpinnerShown(refreshControl: UIRefreshControl) {
        self.sinceShown = Date()
        self.refreshControl = refreshControl
    }
    
    private func hideRefreshSpinner() {
        if refreshControl != nil {
            refreshControl!.endRefreshing()
            refreshControl = nil
        }
    }
    
    func hide() {
        self.hideCalled = true
        let shownSecs = max(0.0, 0.5 - (Date().timeIntervalSince(self.sinceShown)))
        DispatchQueue.main.asyncAfter(deadline: .now() + shownSecs) {
            if !self.isHidden {
                self.activityIndictor.stopAnimating()
                self.isHidden = true
                self.removeFromSuperview()
            }
            if self.refreshControl != nil {
                self.hideRefreshSpinner()
            }
        }
    }
    
}
