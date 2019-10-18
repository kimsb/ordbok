//
//  WorkoutViewController.swift
//  ordbok
//
//  Created by Kim Stephen Bovim on 11/10/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import UIKit

class WorkoutViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UIPopoverPresentationControllerDelegate {
    @IBOutlet weak var presufBaseCountSeg: UISegmentedControl!
    @IBOutlet weak var presufModeSeg: UISegmentedControl!
    @IBOutlet weak var presufExclusiveSeg: UISegmentedControl!
    @IBOutlet weak var presufOrListsSeg: UISegmentedControl!
    @IBOutlet weak var wordLabel: UILabel!
    @IBOutlet weak var feedbackLabel: UILabel!
    @IBOutlet weak var userInputTextField: UITextField!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var customListsTextField: UITextField!
    @IBOutlet weak var createListButton: UIButton!
    @IBOutlet weak var deleteListButton: UIButton!
    @IBOutlet weak var wrongAnswerButton: UIButton!
    @IBOutlet weak var rightAnswerButton: UIButton!
    let uiPickerView = UIPickerView()
    var customListKeys: [String] = []
    var isExclusive: Bool!
    var isPrefix: Bool!
    var selectedCustomList: String?
    
    var question: Question?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let loadedWorkoutSettings = NSKeyedUnarchiver.unarchiveObject(withFile: WorkoutSettings.ArchiveURL.path) as? WorkoutSettings {
            presufBaseCountSeg.selectedSegmentIndex = loadedWorkoutSettings.presufBaseCountSelect
            presufModeSeg.selectedSegmentIndex = loadedWorkoutSettings.presufModeSelect
            presufExclusiveSeg.selectedSegmentIndex = loadedWorkoutSettings.presufExclusiveSelect
            presufOrListsSeg.selectedSegmentIndex = loadedWorkoutSettings.presufOrListsSelect
            selectedCustomList = loadedWorkoutSettings.selectedCustomList
        }
        loadPicker()
        hideUIElements()
        isPrefix = presufModeSeg.selectedSegmentIndex == 0
        isExclusive = presufExclusiveSeg.selectedSegmentIndex == 0
        updateQuestions()
        if (presufOrListsSeg.selectedSegmentIndex == 0) {
            userInputTextField.becomeFirstResponder()
        }
    }
    
    func loadPicker(listName: String? = nil) {
        customListKeys = Ordlister.shared.getCustomLists().keys.sorted()
        uiPickerView.delegate = self
        customListsTextField.inputView = uiPickerView
        if (customListKeys.isEmpty) {
            customListsTextField.isUserInteractionEnabled = false
        } else {
            customListsTextField.isUserInteractionEnabled = customListKeys.count > 1
            if (listName != nil) {
                customListsTextField.text = listName!
            } else if (selectedCustomList != nil) {
                customListsTextField.text = selectedCustomList!
            } else {
                customListsTextField.text = customListKeys.first!
            }
            uiPickerView.selectRow(customListKeys.index(of: customListsTextField.text!)!, inComponent: 0, animated: false)
        }
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return customListKeys.count
    }
    
    func pickerView( _ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return customListKeys[row]
    }
    
    func pickerView( _ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        customListsTextField.text = customListKeys[row]
        selectedCustomList = customListKeys[row]
        saveSettings()
        updateQuestions()
        self.view.endEditing(true)
    }
    
    func hideUIElements() {
        let hideCustomLists = presufOrListsSeg.selectedSegmentIndex == 0
        customListsTextField.isHidden = hideCustomLists
        createListButton.isHidden = hideCustomLists
        deleteListButton.isHidden = hideCustomLists
        wrongAnswerButton.isHidden = hideCustomLists
        rightAnswerButton.isHidden = hideCustomLists
        presufBaseCountSeg.isHidden = !hideCustomLists
        presufModeSeg.isHidden = !hideCustomLists
        presufExclusiveSeg.isHidden = !hideCustomLists
    }
    
    func saveSettings() {
        let workoutSettings = WorkoutSettings(presufBaseCountSelect: self.presufBaseCountSeg.selectedSegmentIndex, presufModeSelect: self.presufModeSeg.selectedSegmentIndex, presufExclusiveSelect: self.presufExclusiveSeg.selectedSegmentIndex, presufOrListsSelect: self.presufOrListsSeg.selectedSegmentIndex, selectedCustomList: self.selectedCustomList)
        DispatchQueue.global(qos: .userInitiated).async {
            NSKeyedArchiver.archiveRootObject(workoutSettings, toFile: WorkoutSettings.ArchiveURL.path)
        }
    }
    
    private func getQuestions() -> Questions? {
        return presufOrListsSeg.selectedSegmentIndex == 0
            ? Ordlister.shared.getPreSufQuestions(isPrefix: isPrefix, isExclusive: isExclusive, baseCount: presufBaseCountSeg.selectedSegmentIndex + 2)!
            : Ordlister.shared.getCustomLists()[customListsTextField.text!] ?? nil
    }
    
    func showNextQuestion(correctAnswer: Bool? = nil) {
        if let correctAnswer = correctAnswer {
            question!.setTimeToShow(answeredCorrect: correctAnswer)
            question = getQuestions()!.getNextQuestion(lastQuestion: question)
        } else {
            question = getQuestions()?.getNextQuestion()
        }
        wordLabel.text = presufOrListsSeg.selectedSegmentIndex == 0
            ? "\(isPrefix ? "?" : "")\(question!.hint)\(isPrefix ? "" : "?")"
            : question?.hint ?? ""
        userInputTextField.text = ""
        if (question == nil) {
            countLabel.text = ""
            rightAnswerButton.isHidden = true
        } else {
            countLabel.text = "Nye: \(getQuestions()!.newQuestions.count), sett: \(getQuestions()!.seenQuestions.count)"
            rightAnswerButton.isHidden = presufOrListsSeg.selectedSegmentIndex == 0
            rightAnswerButton.setTitle("Vis svar", for: .normal)
        }
        wrongAnswerButton.setTitle("", for: .normal)
        wrongAnswerButton.isUserInteractionEnabled = false
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
            userInputTextField.becomeFirstResponder()
        } else {
            self.view.endEditing(true)
        }
        hideUIElements()
        updateQuestions()
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
        if (presufOrListsSeg.selectedSegmentIndex == 0) {
            userInputTextField.becomeFirstResponder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector:#selector(prepareForInput), name:UIApplication.didBecomeActiveNotification, object:UIApplication.shared
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "popover" {
            let destination = segue.destination
            if let popover = destination.popoverPresentationController {
                popover.delegate = self
            }
        }
    }
    
    func makeListPopOverDismissed(listName: String? = nil) {
        if (listName != nil) {
            loadPicker(listName: listName)
            self.feedbackLabel.text = ""
            self.saveSettings()
            self.showNextQuestion()
            self.view.endEditing(true)
        }
    }
    
    @IBAction func deleteList(_ sender: Any) {
        if (customListsTextField.text! != "") {
            let alert = UIAlertController(title: "Er du sikker?", message: "Vil du slette listen: \"\(customListsTextField.text!)\"?", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in                    Ordlister.shared.deleteCustomList(name: self.customListsTextField.text!)
                self.customListKeys = Ordlister.shared.getCustomLists().keys.sorted()
                self.selectedCustomList = self.customListKeys.first
                self.customListsTextField.text = self.selectedCustomList
                self.loadPicker()
                self.feedbackLabel.text = ""
                self.saveSettings()
                self.showNextQuestion()
            }))
            alert.addAction(UIAlertAction(title: "Avbryt", style: .cancel, handler: { (action: UIAlertAction!) in
            }))
            self.present(alert, animated: true, completion: nil)
        }
    }
    @IBAction func wrongAnswerAction(_ sender: Any) {
        let answers = question!.answer.joined(separator: ", ")
        feedbackLabel.textColor = UIColor.red
        feedbackLabel.text = "\u{2717} Feil! Riktig svar: \(answers)"
        showNextQuestion(correctAnswer: false)
    }
    @IBAction func rightAnswerButton(_ sender: Any) {
        let answers = question!.answer.joined(separator: ", ")
        if (rightAnswerButton.titleLabel?.text! == "Vis svar") {
            if #available(iOS 13.0, *) {
                if traitCollection.userInterfaceStyle == .light {
                    feedbackLabel.textColor = UIColor.black
                } else {
                    feedbackLabel.textColor = UIColor.white
                }
            } else {
                feedbackLabel.textColor = UIColor.black
            }
            feedbackLabel.text = answers
            wrongAnswerButton.setTitle("\u{2717} nope...", for: .normal)
            wrongAnswerButton.isUserInteractionEnabled = true
            rightAnswerButton.setTitle("\u{2713} YES!", for: .normal)
        } else {
            wrongAnswerButton.setTitle("", for: .normal)
            wrongAnswerButton.isUserInteractionEnabled = false
            rightAnswerButton.setTitle("Vis svar", for: .normal)
            feedbackLabel.textColor = UIColor.green
            feedbackLabel.text = "\u{2713} Riktig! \(answers)"
            showNextQuestion(correctAnswer: true)
        }
    }
    
}
