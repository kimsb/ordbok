//
//  WorkoutViewController.swift
//  ordbok
//
//  Created by Kim Stephen Bovim on 11/10/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import UIKit

class WorkoutViewController: UIViewController {
    
    @IBOutlet weak var presufBaseCountSeg: UISegmentedControl!
    @IBOutlet weak var presufModeSeg: UISegmentedControl!
    @IBOutlet weak var presufExclusiveSeg: UISegmentedControl!
    @IBOutlet weak var presufOrListsSeg: UISegmentedControl!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var feedbackLabel: UILabel!
    @IBOutlet weak var userInputTextField: UITextField!
    @IBOutlet weak var countLabel: UILabel!
    var isExclusive: Bool!
    var isPrefix: Bool!
    
    var question: Question?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let loadedWorkoutSettings = NSKeyedUnarchiver.unarchiveObject(withFile: WorkoutSettings.ArchiveURL.path) as? WorkoutSettings {
            presufBaseCountSeg.selectedSegmentIndex = loadedWorkoutSettings.presufBaseCountSelect
            presufModeSeg.selectedSegmentIndex = loadedWorkoutSettings.presufModeSelect
            presufExclusiveSeg.selectedSegmentIndex = loadedWorkoutSettings.presufExclusiveSelect
            presufOrListsSeg.selectedSegmentIndex = loadedWorkoutSettings.presufOrListsSelect
        }
        
        isPrefix = presufModeSeg.selectedSegmentIndex == 0
        isExclusive = presufExclusiveSeg.selectedSegmentIndex == 0
        updateQuestions()
        userInputTextField.becomeFirstResponder()
    }
    
    func saveSettings() {
        let workoutSettings = WorkoutSettings(presufBaseCountSelect: presufBaseCountSeg.selectedSegmentIndex, presufModeSelect: presufModeSeg.selectedSegmentIndex, presufExclusiveSelect: presufExclusiveSeg.selectedSegmentIndex, presufOrListsSelect: presufOrListsSeg.selectedSegmentIndex)
        NSKeyedArchiver.archiveRootObject(workoutSettings, toFile: WorkoutSettings.ArchiveURL.path)
    }
    
    private func getQuestions() -> Questions {
        return Ordlister.shared.getQuestions(isPrefix: isPrefix, isExclusive: isExclusive, baseCount: presufBaseCountSeg.selectedSegmentIndex + 2)!
    }
    
    func showNextQuestion(correctAnswer: Bool? = nil) {
        if let correctAnswer = correctAnswer {
            question!.setTimeToShow(answeredCorrect: correctAnswer)
            question = getQuestions().getNextQuestion(lastQuestion: question)
        } else {
            question = getQuestions().getNextQuestion()
        }
        wordLabel.text = "\(isPrefix ? "?" : "")\(question!.hint)\(isPrefix ? "" : "?")"
        userInputTextField.text = ""
        countLabel.text = "Nye: \(getQuestions().newQuestions.count), sett: \(getQuestions().seenQuestions.count)"
    }
    
    func updateQuestions() {
        showNextQuestion()
        feedbackLabel.text = ""
    }
    
    @IBAction func presufBaseCountChanged(_ sender: Any) {
        updateQuestions()
        saveSettings()
    }
    
    @IBAction func presufModeChanged(_ sender: Any) {
        isPrefix = presufModeSeg.selectedSegmentIndex == 0
        updateQuestions()
        saveSettings()
    }
    
    @IBAction func presufExclusiveChanged(_ sender: Any) {
        isExclusive = presufExclusiveSeg.selectedSegmentIndex == 0
        updateQuestions()
        saveSettings()
    }
    
    @IBAction func presufOrListsChanged(_ sender: Any) {
        if (presufOrListsSeg.selectedSegmentIndex == 0) {
            updateQuestions()
            feedbackLabel.text = ""
        } else {
            wordLabel.text = "Ikke laget ennå."
            
            if #available(iOS 13.0, *) {
                if traitCollection.userInterfaceStyle == .light {
                    feedbackLabel.textColor = UIColor.black
                } else {
                    feedbackLabel.textColor = UIColor.white
                }
            } else {
                feedbackLabel.textColor = UIColor.black
            }
            
            feedbackLabel.text = "Ikke vær så utålmodig, a..."
        }
        saveSettings()
    }
    
    @IBAction func userInputChanged(_ sender: Any) {        
        var userInput = userInputTextField.text!.uppercased()
        let correctWord = isPrefix ? "\(question!.answer.first ?? "")\(question!.hint)" : "\(question!.hint)\(question!.answer.first ?? "")"
        
        if (isExclusive) {
            if (question!.answer.first! == userInput) {
                feedbackLabel.textColor = UIColor.green
                feedbackLabel.text = "\u{2713} \(correctWord) er riktig!"
                showNextQuestion(correctAnswer: true)
            } else {
                feedbackLabel.textColor = UIColor.red
                feedbackLabel.text = "\u{2717} riktig svar er \(correctWord)..."
                showNextQuestion(correctAnswer: false)
            }
        } else {
            if (userInput.count > 0 && Array(userInput.prefix(userInput.count-1)).contains(Array(userInput).last!)) {
                userInput = String(userInput.prefix(userInput.count-1))
                userInputTextField.text = userInput
            }
            
            if (isPrefix) {
                wordLabel.text = "(\(userInput)) ? \(question!.hint)"
            } else {
                wordLabel.text = "\(question!.hint) ? (\(userInput))"
            }
        }
        
        
    }
    
    @IBAction func userPressedEnter(_ sender: Any) {
        let inputArray = Array(userInputTextField.text!.uppercased()).sorted()
        if (inputArray.count == question!.answer.count) {
            var noWrongAnswers = true
            for index in (0..<inputArray.count) {
                if (String(inputArray[index]) != question!.answer[index]) {
                    noWrongAnswers = false
                }
            }
            if (noWrongAnswers) {
                feedbackLabel.textColor = UIColor.green
                if (inputArray.count == 0) {
                    feedbackLabel.text = "\u{2713} Riktig! \(question!.hint) har ingen \(isPrefix ? "prefix" : "suffix")"
                } else {
                    feedbackLabel.text = "\u{2713} Riktig\(inputArray.count > 1 ? "e" : "") \(isPrefix ? "prefix" : "suffix") for \(question!.hint): \(question!.answer.joined(separator: ", "))"
                }
                showNextQuestion(correctAnswer: true)
                return
            }
        }
        feedbackLabel.textColor = UIColor.red
        if (question!.answer.count == 0) {
            feedbackLabel.text = "\u{2717} Feil! \(question!.hint) har ingen \(isPrefix ? "prefix" : "suffix")..."
        } else {
            feedbackLabel.text = "\u{2717} Riktig\(question!.answer.count > 1 ? "e" : "") \(isPrefix ? "prefix" : "suffix") for \(question!.hint): \(question!.answer.joined(separator: ", "))"
        }
        showNextQuestion(correctAnswer: false)
    }
    
    @objc func prepareForInput() {
        userInputTextField.text = ""
        userInputTextField.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector:#selector(prepareForInput), name:UIApplication.didBecomeActiveNotification, object:UIApplication.shared
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
