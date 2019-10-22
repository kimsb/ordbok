//
//  Ordlister.swift
//  ordbok
//
//  Created by Kim Stephen Bovim on 11/10/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import Foundation

class Ordlister {
    
    static let shared = Ordlister()
    
    let nsf: Dawg
    let tanums: Dawg
    private var allPreSuf: [String:[Int:Questions]]
    private var customLists: [String:Questions]
    
    struct PropertyKey {
        static let prefix = "prefix"
        static let suffix = "suffix"
        static let exclusivePrefix = "exclusivePrefix"
        static let exclusiveSuffix = "exclusiveSuffix"
    }
    
    func getPreSufQuestions(isPrefix: Bool, isExclusive: Bool, baseCount: Int) -> Questions? {
        if (isPrefix) {
            if (isExclusive) {
                return allPreSuf[PropertyKey.exclusivePrefix]![baseCount]
            }
            return allPreSuf[PropertyKey.prefix]![baseCount]
        } else {
            if (isExclusive) {
                return allPreSuf[PropertyKey.exclusiveSuffix]![baseCount]
            }
            return allPreSuf[PropertyKey.suffix]![baseCount]
        }
    }
    
    func saveQuestions() {
        DispatchQueue.global(qos: .userInitiated).async {
            NSKeyedArchiver.archiveRootObject(self.allPreSuf, toFile: Questions.ArchiveURLPreSuf.path)
            NSKeyedArchiver.archiveRootObject(self.customLists, toFile: Questions.ArchiveURLCustomLists.path)
        }
    }
    
    func addCoolPresuf(isPrefix: Bool, isExclusive: Bool, questions: Questions) {
        if (isPrefix) {
            if (isExclusive) {
                allPreSuf[PropertyKey.exclusivePrefix]![6] = questions
            } else {
                allPreSuf[PropertyKey.prefix]![6] = questions
            }
        } else {
            if (isExclusive) {
                allPreSuf[PropertyKey.exclusiveSuffix]![6] = questions
            } else {
                allPreSuf[PropertyKey.suffix]![6] = questions
            }
        }
        saveQuestions()
    }
    
    func getCustomLists() -> [String:Questions] {
        return customLists
    }
    
    func addCustomList(name: String, questions: Questions) {
        customLists[name] = questions
        saveQuestions()
    }
    
    func deleteCustomList(name: String) {
        customLists.removeValue(forKey: name)
        saveQuestions()
    }
    
    private init() {
        //dette tar ca 1 sekund - kan det flyttes ut til lagring?
        nsf = Dawg.load(from: Bundle.main.path(forResource: "nsf2019.bin", ofType: nil)!)!
        tanums = Dawg.load(from: Bundle.main.path(forResource: "tanum.bin", ofType: nil)!)!
        
        if let loadedCustomLists = NSKeyedUnarchiver.unarchiveObject(withFile: Questions.ArchiveURLCustomLists.path) as? [String:Questions] {
            customLists = loadedCustomLists
        } else {
            customLists = [String:Questions]()
        }
            
        if let loadedQuestions = NSKeyedUnarchiver.unarchiveObject(withFile: Questions.ArchiveURLPreSuf.path) as? [String:[Int:Questions]] {
            allPreSuf = loadedQuestions
        } else {
            allPreSuf = [String:[Int:Questions]]()
            allPreSuf[PropertyKey.prefix] = [Int:Questions]()
            allPreSuf[PropertyKey.exclusivePrefix] = [Int:Questions]()
            allPreSuf[PropertyKey.suffix] = [Int:Questions]()
            allPreSuf[PropertyKey.exclusiveSuffix] = [Int:Questions]()
            
            //dette tar ca 5 sekunder
            var lettersFromRack:[Character] = ["?"]
            for baseCount in 2...5 {
                var prefix = [Question]()
                var suffix = [Question]()
                var exclusivePrefix = [Question]()
                var exclusiveSuffix = [Question]()
                lettersFromRack.append("?")
                
                if let allWordsWithBaseCount = nsf.anagrams(withLetters: lettersFromRack, wordLength: baseCount) {
                    for word in allWordsWithBaseCount {
                        let wordScore = getWordScore(word: word)
                        var filledLettersPrefix = [Int:Character]()
                        var filledLettersSuffix = [Int:Character]()
                        let wordArray = Array(word)
                        for index in (0..<word.count) {
                            filledLettersPrefix[index+1] = wordArray[index]
                            filledLettersSuffix[index] = wordArray[index]
                        }
                        
                        if let prefixes = nsf.anagrams(withLetters: ["?"], wordLength: baseCount+1, filledLetters: filledLettersPrefix) {
                            let prefixLetters = prefixes.map { String(Array($0)[0]) } .sorted()
                            if (prefixes.count == 1) {
                                exclusivePrefix.append(Question(hint: word, answer: [prefixLetters.first!], hintScore: wordScore))
                            }
                            prefix.append(Question(hint: word, answer: prefixLetters, hintScore: wordScore))
                        } else {
                            prefix.append(Question(hint: word, answer: [], hintScore: wordScore))
                        }
                        
                        if let suffixes = nsf.anagrams(withLetters: ["?"], wordLength: baseCount+1, filledLetters: filledLettersSuffix) {
                            let suffixLetters = suffixes.map { String(Array($0)[baseCount]) } .sorted()
                            if (suffixes.count == 1) {
                                exclusiveSuffix.append(Question(hint: word, answer: [suffixLetters.first!], hintScore: wordScore))
                            }
                            suffix.append(Question(hint: word, answer: suffixLetters, hintScore: wordScore))
                        } else {
                            suffix.append(Question(hint: word, answer: [], hintScore: wordScore))
                        }
                    }
                }
                self.allPreSuf[PropertyKey.prefix]![baseCount] = Questions(newQuestions: prefix.sorted(by: { $0.hintScore > $1.hintScore } ))
                self.allPreSuf[PropertyKey.suffix]![baseCount] = Questions(newQuestions: suffix.sorted(by: { $0.hintScore > $1.hintScore } ))
                self.allPreSuf[PropertyKey.exclusivePrefix]![baseCount] = Questions(newQuestions: exclusivePrefix.sorted(by: { $0.hintScore > $1.hintScore } ))
                self.allPreSuf[PropertyKey.exclusiveSuffix]![baseCount] = Questions(newQuestions: exclusiveSuffix.sorted(by: { $0.hintScore > $1.hintScore } ))
            }
        }
    }
    
    func getWordScore(word: String) -> Int {
        var lettersRemaining = letterCounts
        var sum = 0
        for letter in Array(word) {
            if let count = lettersRemaining[letter] {
                if (count > 0) {
                    lettersRemaining[letter] = count - 1
                    if let score = letterScores[letter] {
                        sum += score
                    }
                }
            }
            
        }
        return sum
    }
    
    private let letterScores: [Character:Int] = ["A":1, "B":4, "C":10, "D":1, "E":1, "F":2, "G":2, "H":3, "I":1, "J":4, "K":2, "L":1, "M":2, "N":1, "O":2, "P":4, "R":1, "S":1, "T":1, "U":4, "V":4, "W":8, "Y":6, "Æ":6, "Ø":5, "Å":4]
    private let letterCounts: [Character:Int] = ["A":7, "B":3, "C":1, "D":5, "E":9, "F":4, "G":4, "H":3, "I":5, "J":2, "K":4, "L":5, "M":3, "N":6, "O":4, "P":2, "R":6, "S":6, "T":6, "U":3, "V":3, "W":1, "Y":1, "Æ":1, "Ø":2, "Å":2]
}
