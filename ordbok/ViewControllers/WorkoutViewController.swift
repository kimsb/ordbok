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
    @IBOutlet weak var lastShownLabel: UILabel!
    @IBOutlet weak var customListsTextField: UITextField!
    @IBOutlet weak var createListButton: UIButton!
    @IBOutlet weak var deleteListButton: UIButton!
    @IBOutlet weak var wrongAnswerButton: UIButton!
    @IBOutlet weak var rightAnswerButton: UIButton!
    @IBOutlet weak var addToListButton: UIButton!
    let uiPickerView = UIPickerView()
    var customListKeys: [String] = []
    var isExclusive: Bool!
    var isPrefix: Bool!
    var selectedCustomList: String?
    
    var question: Question?
    var lastQuestion: Question?
    
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
        addToListButton.isHidden = hideCustomLists
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
        if #available(iOS 13.0, *) {
            if traitCollection.userInterfaceStyle == .light {
                lastShownLabel.textColor = UIColor.black
            } else {
                lastShownLabel.textColor = UIColor.white
            }
        } else {
            lastShownLabel.textColor = UIColor.black
        }
        
        if let correctAnswer = correctAnswer {
            lastQuestion = question
            question!.setTimeToShow(answeredCorrect: correctAnswer)
            question = getQuestions()!.getNextQuestion(lastQuestion: question)
        } else {
            lastQuestion = nil
            question = getQuestions()?.getNextQuestion()
        }
        wordLabel.text = presufOrListsSeg.selectedSegmentIndex == 0
            ? "\(isPrefix ? "?" : "")\(question!.hint)\(isPrefix ? "" : "?")"
            : question?.hint ?? ""
        userInputTextField.text = ""
        if (question == nil) {
            countLabel.text = ""
            lastShownLabel.text = ""
            rightAnswerButton.isHidden = true
        } else {
            if (question!.lastShown == nil) {
                lastShownLabel.text = ""
            } else {
                lastShownLabel.text = "Sist sett: \(daysSinceString(date: question!.lastShown!))"
            }
            if (question!.timeToShow != Date.distantFuture) {
                let lastShownString = lastShownLabel.text!
                let daysSinceLastShown = daysSince(date: question!.timeToShow)
                if (daysSinceLastShown >= 0 ) {
                    lastShownLabel.textColor = UIColor.red
                }
                lastShownLabel.text = "\(lastShownString.count > 0 ? "\(lastShownString) - " : "")Due: \(daysSinceString(date: question!.timeToShow))"
            }
            countLabel.text = "Nye: \(getQuestions()!.newQuestions.count), sett: \(getQuestions()!.seenQuestions.count)"
            rightAnswerButton.isHidden = presufOrListsSeg.selectedSegmentIndex == 0
            rightAnswerButton.setTitle("Vis svar", for: .normal)
        }
        wrongAnswerButton.setTitle("", for: .normal)
        wrongAnswerButton.isUserInteractionEnabled = false
    }
    
    func daysSince(date: Date) -> Int {
        let calendar = Calendar.current
        // Replace the hour (time) of both dates with 00:00
        let lastShown = calendar.date(bySettingHour: 12, minute: 00, second: 00, of: calendar.startOfDay(for: date))!
        let today = calendar.date(bySettingHour: 12, minute: 00, second: 00, of: calendar.startOfDay(for: Date()))!
        let components = calendar.dateComponents([.day], from: lastShown, to: today)
        return components.day!
    }
    
    func daysSinceString(date: Date) -> String {
        let daysSinceLastShown = daysSince(date: date)
        if (daysSinceLastShown == 0) {
            return "i dag"
        } else if (daysSinceLastShown < 0) {
            return "om \(abs(daysSinceLastShown)) dag\(daysSinceLastShown < -1 ? "er" : "")"
        } else {
            return "\(daysSinceLastShown) dag\(daysSinceLastShown > 1 ? "er" : "") siden"
        }
    }
    
    func updateQuestions() {
        let coolPresufExists = Ordlister.shared.getPreSufQuestions(isPrefix: isPrefix, isExclusive: isExclusive, baseCount: 6) != nil
        if (!coolPresufExists && presufBaseCountSeg.selectedSegmentIndex == 4) {
            presufBaseCountSeg.selectedSegmentIndex = 3
        }
        presufBaseCountSeg.setEnabled(coolPresufExists, forSegmentAt: 4)
        showNextQuestion()
        addToListButton.isHidden = true
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
            addToListButton.isHidden = presufBaseCountSeg.selectedSegmentIndex == 4
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
        addToListButton.isHidden = false
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
        
        let inputStringArray = inputArray.map { String($0) }
        let inputAsJoinedString = "\(inputStringArray.isEmpty ? "" : " ")\(inputStringArray.joined(separator: ", "))"
        let attributedInput = NSMutableAttributedString(string: inputAsJoinedString)
        let attributedFeedback = NSMutableAttributedString(string: "Du skrev\(inputStringArray.isEmpty ? " ingenting" : ":")")
        
        for letter in inputStringArray {
            if (!question!.answer.contains(letter)) {
                let range = (inputAsJoinedString as NSString).range(of: " \(letter)")
                attributedInput.addAttribute(NSAttributedString.Key.strikethroughStyle,
                                     value: NSUnderlineStyle.single.rawValue,
                                     range: range)
            }
        }
        attributedFeedback.append(attributedInput)
                
        if (question!.answer.count == 0) {
            let feedbackEnd = ",\nmen \(question!.hint) har ingen \(isPrefix ? "prefix" : "suffix")..."
            attributedFeedback.append(NSMutableAttributedString(string: feedbackEnd))
            feedbackLabel.attributedText = attributedFeedback
        } else {
            
            let answerAsJoinedString = " \(question!.answer.joined(separator: ", "))"
            let attributedAnswer = NSMutableAttributedString(string: answerAsJoinedString)
            for letter in question!.answer {
                if (!inputStringArray.contains(letter)) {
                    let range = (answerAsJoinedString as NSString).range(of: " \(letter)")
                    attributedAnswer.addAttribute(NSAttributedString.Key.underlineStyle,
                                         value: NSUnderlineStyle.single.rawValue,
                                         range: range)
                }
            }
            
            let feedbackEnd = ",\nriktig\(question!.answer.count > 1 ? "e" : "") \(isPrefix ? "prefix" : "suffix") for \(question!.hint):"
            attributedFeedback.append(NSMutableAttributedString(string: feedbackEnd))
            attributedFeedback.append(attributedAnswer)
            feedbackLabel.attributedText = attributedFeedback
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
    
    @IBAction func addToListPressed(_ sender: Any) {
        if lastQuestion == nil {
            return
        }
        if let storedCoolInexclusivePresuf = Ordlister.shared.getPreSufQuestions(isPrefix: isPrefix, isExclusive: false, baseCount: 6) {
            storedCoolInexclusivePresuf.addQuestion(newQuestion: lastQuestion!)
            Ordlister.shared.addCoolPresuf(isPrefix: isPrefix, isExclusive: false, questions: storedCoolInexclusivePresuf)
            if let storedCoolExclusivePresuf = Ordlister.shared.getPreSufQuestions(isPrefix: isPrefix, isExclusive: false, baseCount: 6) {
                storedCoolExclusivePresuf.addQuestion(newQuestion: lastQuestion!)
                Ordlister.shared.addCoolPresuf(isPrefix: isPrefix, isExclusive: true, questions: storedCoolInexclusivePresuf)
            }
        } else {
            Ordlister.shared.addCoolPresuf(isPrefix: isPrefix, isExclusive: false, questions: Questions(newQuestions: [lastQuestion!]))
            if (isExclusive) {
                Ordlister.shared.addCoolPresuf(isPrefix: isPrefix, isExclusive: true, questions: Questions(newQuestions: [lastQuestion!]))
            }
        }
        presufBaseCountSeg.setEnabled(true, forSegmentAt: 4)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .popover
        //return .none
    }
    
}
