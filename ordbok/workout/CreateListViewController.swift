//
//  CreateListViewController.swift
//  ordbok
//
//  Created by Kim Stephen Bovim on 13/10/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import UIKit

class CreateListViewController: UIViewController {
    
    @IBOutlet weak var maxLettersTextField: UITextField!
    @IBOutlet weak var listRulesTextField: UITextField!
    @IBOutlet weak var listContainsTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        listRulesTextField.becomeFirstResponder()
        // Do any additional setup after loading the view.
    }
    
    func makeList() {
        if (!allInputIsValid()) {
            return
        }
        let minLetters = getMinLetters()
        let maxLetters = getMaxLetters()
        
        if (getMinLetters() > getMaxLetters()) {
            let alert = UIAlertController(title: "Ugyldig input", message: "Maks antall bokstaver er satt til mindre enn \(minLetters)", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in                    self.maxLettersTextField.becomeFirstResponder()
                self.maxLettersTextField.selectAll(nil)}))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let listRules = getListRules()
        let contains = getListContains()
        
        ActivitySpinner.shared.show(text: "Lager liste...", holdingViewController: self)
        DispatchQueue.global(qos: .userInitiated).async {
            self.findAnagramsFor(listRules: listRules, contains: contains, minLetters: minLetters, maxLetters: maxLetters)
        }
        
    }
    
    func findAnagramsFor(listRules: String, contains: String, minLetters: Int, maxLetters: Int) {
        var separatedQuestionMarks = 0
        var nonQuestionMarks = 0
        var strippedListRules = [Character]()
        let listRuleArray = Array(listRules)
        for index in 0..<listRuleArray.count {
            if (listRuleArray[index] == "?") {
                if (index == 0 || listRuleArray[index-1] != "?") {
                    separatedQuestionMarks += 1
                    strippedListRules.append("?")
                }
            } else {
                nonQuestionMarks += 1
                strippedListRules.append(listRuleArray[index])
            }
        }
        
        let containsTextWithPlusInFront = contains.isEmpty ? "" : " + \(contains)"
        let wordCountText = maxLetters > minLetters ? "-\(maxLetters)" : ""
        
        let listName = "\(minLetters)\(wordCountText)-bokstavers ord: \(String(strippedListRules))\(containsTextWithPlusInFront)"
        
        if (Ordlister.shared.getCustomLists()[listName] != nil) {
            DispatchQueue.main.async(execute: {
                
                let alert = UIAlertController(title: "Ugyldig input", message: "Listen finnes allerede", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in                    self.listRulesTextField.becomeFirstResponder()
                    self.listRulesTextField.selectAll(nil)}))
                self.present(alert, animated: true, completion: nil)
                
            })
            ActivitySpinner.shared.hide()
            return
        }
        
        allQuestionMarkPermutations = [Int:[[Int]]]()
        let minSum = minLetters - nonQuestionMarks
        calculateQuestionMarkPermutations(permutations: [], currentSum: 0, minSum: minSum, maxSum: maxLetters-nonQuestionMarks, maxDepth: separatedQuestionMarks)
        
        var allQuestions = [Question]()
        for letterCount in minLetters...maxLetters {
            var words = Set<String>()
            for permutations in self.allQuestionMarkPermutations[letterCount - (minSum > 0 ? (minLetters-minSum) : minLetters)] ?? [[]] {
                var withLetters = [Character]()
                var filledLetters = [Int:Character]()
                var questionMarkCount = 0
                var index = 0
                var containsIndex = 0
                let containsArray = Array(contains)
                for letter in Array(strippedListRules) {
                    if (letter == "?") {
                        for _ in 0..<permutations[questionMarkCount] {
                            if (containsIndex < containsArray.count) {
                                withLetters.append(containsArray[containsIndex])
                                containsIndex += 1
                            } else {
                                withLetters.append("?")
                            }
                            index += 1
                        }
                        questionMarkCount += 1
                    } else if (letter == "!") {
                        if (containsIndex < containsArray.count) {
                            withLetters.append(containsArray[containsIndex])
                            containsIndex += 1
                        } else {
                            withLetters.append("?")
                        }
                        index += 1
                    } else {
                        filledLetters[index] = letter
                        index += 1
                    }
                }
                
                print("wordlength: \(letterCount), with: \(withLetters), filled: \(filledLetters)")
                
                if let anagrams = Ordlister.shared.nsf.anagrams(withLetters: withLetters, wordLength: letterCount, filledLetters: filledLetters) {
                    words.formUnion(anagrams)
                }
                if (letterCount == 7) {
                    if let tanums = Ordlister.shared.tanums.anagrams(withLetters: withLetters, wordLength: letterCount, filledLetters: filledLetters) {
                        words.formUnion(tanums)
                    }
                }
            }
            if (!words.isEmpty) {
                var alphaMap = [String:[String]]()
                for word in words {
                    let alpha = String(Array(word).sorted())
                    if (alphaMap[alpha] == nil) {
                        alphaMap[alpha] = []
                    }
                    alphaMap[alpha]!.append(word)
                }
                var questions = [Question]()
                for (hint, answers) in alphaMap {
                    questions.append(Question(hint: hint, answer: answers, hintScore: Ordlister.shared.getWordScore(word: hint)))
                }
                allQuestions.append(contentsOf: questions.sorted(by: { $0.hintScore > $1.hintScore } ))
            }
        }
        if (allQuestions.isEmpty) {
            DispatchQueue.main.async(execute: {
                let alert = UIAlertController(title: "Ingen treff", message: "Finner ingen ord med disse kriteriene", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in                    self.listRulesTextField.becomeFirstResponder()
                    self.listRulesTextField.selectAll(nil)}))
                self.present(alert, animated: true, completion: nil)
                ActivitySpinner.shared.hide()
                return
            })
        } else {
            Ordlister.shared.addCustomList(name: listName, questions: Questions(newQuestions: allQuestions))
            DispatchQueue.main.async(execute: {
                self.dismiss(listName: listName)
            })
        }
        ActivitySpinner.shared.hide()
        return
    }
    
    var allQuestionMarkPermutations = [Int:[[Int]]]()
    
    func calculateQuestionMarkPermutations(permutations: [Int], currentSum: Int, minSum: Int, maxSum: Int, maxDepth: Int) {
        var currentPermutations = permutations
        if (currentPermutations.count < maxDepth) {
            for index in 0...maxSum {
                if (index == 0) {
                    currentPermutations.append(index)
                } else {
                    currentPermutations[currentPermutations.count-1] = index
                }
                calculateQuestionMarkPermutations(permutations: currentPermutations, currentSum: currentSum + index, minSum: minSum, maxSum: maxSum, maxDepth: maxDepth)
            }
        } else {
            if (allQuestionMarkPermutations[currentSum] == nil) {
                allQuestionMarkPermutations[currentSum] = []
            }
            let sum = currentPermutations.reduce(0, +)
            if (sum >= minSum && sum <= maxSum) {
                allQuestionMarkPermutations[currentSum]!.append(currentPermutations)
            }
        }
    }
    
    func maxLettersIsValid() -> Bool {
        if (!maxLettersTextField.text!.isEmpty) {
            let maxLetterInput = Int(maxLettersTextField.text!)!
            if !(2 ... 15).contains(maxLetterInput)  {
                let alert = UIAlertController(title: "Ugyldig input", message: "Maks antall bokstaver må være mellom 2 og 15", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in                    self.maxLettersTextField.becomeFirstResponder()
                    self.maxLettersTextField.selectAll(nil)}))
                self.present(alert, animated: true, completion: nil)
                return false
            }
        }
        return true
    }
    
    func getMaxLetters() -> Int {
        let fromMaxField = maxLettersTextField.text!.isEmpty
            ? 15
            : Int(maxLettersTextField.text!)!
        var exclamations = 0
        var knownLetters = 0
        for letter in Array(getListRules()) {
            if (letter == "?") {
                return fromMaxField
            } else if (letter == "!") {
                exclamations += 1
            } else {
                knownLetters += 1
            }
        }
        if (exclamations > 0 || knownLetters > 0) {
            return exclamations + knownLetters
        }
        return fromMaxField
    }
    
    func getMinLetters() -> Int {
        var exclamations = 0
        var knownLetters = 0
        var questionMark = false
        for letter in Array(getListRules()) {
            if (letter == "!") {
                exclamations += 1
            } else if (letter == "?") {
                questionMark = true
            } else {
                knownLetters += 1
            }
        }
        if (!questionMark) {
            return max(exclamations + knownLetters, 2)
        }
        return max(knownLetters + max(exclamations, getListContains().count), 2)
    }
    
    func getMaxContains() ->  Int {
        let maxLetters = getMaxLetters()
        var knownLetters = 0
        var possibleUnknowns = 0
        for letter in Array(getListRules()) {
            if (letter == "!") {
                possibleUnknowns += 1
            } else if (letter == "?") {
                possibleUnknowns = maxLetters
            } else {
                knownLetters += 1
            }
        }
        if (possibleUnknowns >= maxLetters) {
            return maxLetters - knownLetters
        }
        return possibleUnknowns
    }
    
    //TODO : tåle at input i rules bare er ett ?
    func listRulesIsValid() -> Bool {
        let listRules = listRulesTextField.text!.uppercased()
        if ((listRules.count < 2 && listRules != "?") ||
            listRules.count > getMaxLetters() ||
            (listRules.range(of: "^[A-ZÆØÅ!?]+$", options: .regularExpression, range: nil, locale: nil) == nil)) {
            let alert = UIAlertController(title: "Ugyldig input", message: "Kun bokstaver, ! og ? er gyldig input, og du må skrive inn mellom 2 og \(getMaxLetters()) tegn", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in                    self.listRulesTextField.becomeFirstResponder()
                self.listRulesTextField.selectAll(nil)}))
            self.present(alert, animated: true, completion: nil)
            return false
        }
        return true
    }
    
    func getListRules() -> String {
        listRulesTextField.text!.isEmpty
            ? ""
            : listRulesTextField.text!.uppercased()
    }
    
    func listContainsIsValid() -> Bool {
        if (!listContainsTextField.text!.isEmpty) {
            if (listContainsTextField.text!.count > getMaxContains()) {
                let alert = UIAlertController(title: "Ugyldig input", message: "Du har skrevet inn for mange bokstaver", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: { action in                    self.listContainsTextField.becomeFirstResponder()
                    self.listContainsTextField.selectAll(nil)}))
                self.present(alert, animated: true, completion: nil)
                return false;
            }
        }
        return true
    }
    
    func getListContains() -> String {
        return listContainsTextField.text!.isEmpty
            ? ""
            : listContainsTextField.text!.uppercased()
    }
    
    func allInputIsValid() -> Bool {
        return maxLettersIsValid() && listRulesIsValid() && listContainsIsValid()
    }
    
    @IBAction func maxLettersEntered(_ sender: Any) {
        if (maxLettersIsValid()) {
            listRulesTextField.becomeFirstResponder()
        }
    }
    
    @IBAction func listRulesEntered(_ sender: Any) {
        if (listRulesIsValid()) {
            listContainsTextField.becomeFirstResponder()
        }
    }
    
    @IBAction func listContainsEntered(_ sender: Any) {
        if (listContainsIsValid()) {
            makeList()
        }
    }
    
    @IBAction func makeListButton(_ sender: Any) {
        makeList()
    }
    
    @IBAction func listContainsDidChange(_ sender: Any) {
        let listContainsText = listContainsTextField.text!.uppercased()
        if (!listContainsText.isEmpty &&
            (listContainsText.range(of: "^[A-ZÆØÅ]+$", options: .regularExpression, range: nil, locale: nil) == nil)) {
            listContainsTextField.text = String(listContainsTextField.text!.prefix(listContainsText.count-1))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        notifyParentController()
    }
    
    func dismiss(listName: String) {
        notifyParentController(listName: listName)
        dismiss(animated: true)
    }
    
    func notifyParentController(listName: String? = nil) {
        let workoutViewController = popoverPresentationController!.delegate as! WorkoutViewController
        workoutViewController.makeListPopOverDismissed(listName: listName)
    }
    
}
