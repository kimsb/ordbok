//
//  ViewController.swift
//  ordbok
//
//  Created by Kim Stephen Bovim on 03/10/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var anagramButton: CustomUIButton!
    @IBOutlet weak var prefiksButton: CustomUIButton!
    @IBOutlet weak var suffiksButton: CustomUIButton!
    @IBOutlet weak var input: UITextField!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addToListButton: UIButton!
    
    var feedback = ""
    var words = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        updateButtonTitle()
        prepareForInput()
    }
    
    func check() {
        view.endEditing(true)
        feedback = ""
        words = []
        tableView.isScrollEnabled = true
        let inputText = input.text!.uppercased()
        if (inputText.count > 1) {
            if (anagramButton.hasBeenPressed) {
                findAnagrams(inputText: inputText)
                if (words.isEmpty) {
                    words.append("-")
                }
            } else if (prefiksButton.hasBeenPressed && suffiksButton.hasBeenPressed) {
                findPrefixes(inputText: inputText)
                findSuffixes(inputText: inputText)
                let finnesINSF = Ordlister.shared.nsf.lookup(inputText)
                if (finnesINSF) {
                    words.append(inputText)
                }
                words.sort()
                words = words.sorted {$0.count < $1.count }
                if (words.isEmpty) {
                    words.append("-")
                }
            } else if (prefiksButton.hasBeenPressed) {
                findPrefixes(inputText: inputText)
                let finnesINSF = Ordlister.shared.nsf.lookup(inputText)
                if (finnesINSF) {
                    words.append(inputText)
                }
                words.sort()
                words = words.sorted {$0.count < $1.count }
                if (words.isEmpty) {
                    words.append("-")
                }
            } else if (suffiksButton.hasBeenPressed) {
                findSuffixes(inputText: inputText)
                let finnesINSF = Ordlister.shared.nsf.lookup(inputText)
                if (finnesINSF) {
                    words.append(inputText)
                }
                words.sort()
                words = words.sorted {$0.count < $1.count }
                if (words.isEmpty) {
                    words.append("-")
                }
            } else {
                checkSingleWord(inputText: inputText)
                tableView.isScrollEnabled = false
            }
        }
        tableView.reloadData()
        self.tableView.layoutIfNeeded()
        self.tableView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    func findSuffixes(inputText: String) {
        var anagrams = [String]()
        
        
        
        for i in (1...(10-inputText.count)) {
            var filledLetters = [Int: Character]()
            let inputTextArray = Array(inputText)
            for index in (0..<inputText.count) {
                filledLetters[index] = inputTextArray[index]
            }
            var withLetters = [Character]()
            for _ in (1...i) {
                withLetters.append("?")
            }
            if let suffix = Ordlister.shared.nsf.anagrams(withLetters: withLetters, wordLength: inputText.count + i, filledLetters: filledLetters) {
                anagrams.append(contentsOf: suffix)
            }
        }
        words.append(contentsOf: anagrams)
    }
    
    func findPrefixes(inputText: String) {
        var anagrams = [String]()
        for i in (1...(10-inputText.count)) {
            var filledLetters = [Int: Character]()
            let inputTextArray = Array(inputText)
            for index in (0..<inputText.count) {
                filledLetters[i+index] = inputTextArray[index]
            }
            var withLetters = [Character]()
            for _ in (1...i) {
                withLetters.append("?")
            }
            if let prefix = Ordlister.shared.nsf.anagrams(withLetters: withLetters, wordLength: inputText.count + i, filledLetters: filledLetters) {
                anagrams.append(contentsOf: prefix)
            }
        }
        words.append(contentsOf: anagrams)
    }
    
    func findAnagrams(inputText: String) {
        for wordLength in (2...inputText.count).reversed() {
            var anagrams = [String]()
            if let nsfAnagrams = Ordlister.shared.nsf.anagrams(withLetters: Array(inputText), wordLength: wordLength) {
                anagrams.append(contentsOf: nsfAnagrams)
            }
            words.append(contentsOf: anagrams.sorted(by: <))
        }
    }
    
    func checkSingleWord(inputText: String) {
        let finnesINSF = Ordlister.shared.nsf.lookup(inputText)
        
        if (finnesINSF) {
            if (inputText.count <= 8) {
                feedback = "GODKJENT!"
            } else {
                feedback = "GODKJENT! (i NSF-lista)"
            }
        } else {
            feedback = "IKKE GODKJENT"
        }
        
        addToListButton.isHidden = !finnesINSF
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return words.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let header = tableView.dequeueReusableCell(withIdentifier: "FeedbackHeader") as! FeedbackHeader        
        header.feedbackLabel.text = feedback
        
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return feedback.isEmpty ? 0 : 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell", for: indexPath) as? TableViewCell  else {
            fatalError("The dequeued cell is not an instance of TableViewCell.")
        }
        cell.cellLabel.text = words[indexPath.row]
        return cell
    }
    
    @IBAction func enterPressed(_ sender: Any) {
        check()
    }
    
    @IBAction func buttonPressed(_ sender: Any) {
        check()
    }
    
    func updateButtonTitle() {
        addToListButton.isHidden = true
        if (anagramButton.hasBeenPressed) {
            button.setTitle("Finn Anagrammer", for: .normal)
        } else if (prefiksButton.hasBeenPressed && suffiksButton.hasBeenPressed) {
            button.setTitle("Finn prefiks og suffiks", for: .normal)
        } else if (prefiksButton.hasBeenPressed) {
            button.setTitle("Finn prefiks", for: .normal)
        } else if (suffiksButton.hasBeenPressed) {
            button.setTitle("Finn suffiks", for: .normal)
        } else {
            button.setTitle("Sjekk ord", for: .normal)
        }
    }
    
    @IBAction func anagramButtonPressed(_ sender: Any) {
        anagramButton.toggle(parentView: self.view)
        prefiksButton.deselect(parentView: self.view)
        suffiksButton.deselect(parentView: self.view)
        updateButtonTitle()
    }
    @IBAction func prefixButtonPressed(_ sender: Any) {
        prefiksButton.toggle(parentView: self.view)
        anagramButton.deselect(parentView: self.view)
        updateButtonTitle()
    }
    @IBAction func suffixButtonPressed(_ sender: Any) {
        suffiksButton.toggle(parentView: self.view)
        anagramButton.deselect(parentView: self.view)
        updateButtonTitle()
    }
    
    @IBAction func inputEditingChanged(_ sender: Any) {
        feedback = ""
        words = []
        tableView.reloadData()
    }
    
    @IBAction func inputTouchDown(_ sender: Any) {
        prepareForInput()
    }
    
    @objc func prepareForInput() {
        input.becomeFirstResponder()
        input.selectAll(nil)
        addToListButton.isHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector:#selector(prepareForInput), name:UIApplication.didBecomeActiveNotification, object:UIApplication.shared
        )
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func addToListButtonPressed(_ sender: Any) {
        let inputAlpha = String(Array(input.text!.uppercased()).sorted())
        
        DispatchQueue.global(qos: .userInitiated).async {
            let coolList = Ordlister.shared.getCustomLists()["- Kule ord -"] ?? Questions(newQuestions: [])
            if (coolList.newQuestions.filter { $0.hint == inputAlpha }.isEmpty
                && coolList.seenQuestions.filter { $0.hint == inputAlpha }.isEmpty ) {
                var anagrams = [String]()
                if let nsfAnagrammer = Ordlister.shared.nsf.anagrams(withLetters: Array(inputAlpha), wordLength: inputAlpha.count) {
                    anagrams.append(contentsOf: nsfAnagrammer)
                }
                coolList.addQuestion(newQuestion: Question(hint: inputAlpha, answer: anagrams, hintScore: Ordlister.shared.getWordScore(word: inputAlpha)))
                
                Ordlister.shared.addCustomList(name: "- Kule ord -", questions: coolList)
            }
        }
    }
}
