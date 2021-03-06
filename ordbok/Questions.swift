//
//  Questions.swift
//  ordbok
//
//  Created by Kim Stephen Bovim on 11/10/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import Foundation

class Questions: NSObject, Codable, NSCoding {
    var newQuestions: [Question]
    var seenQuestions: [Question]
    
    init(newQuestions: [Question], seenQuestions: [Question] = []) {
        self.newQuestions = newQuestions
        self.seenQuestions = seenQuestions
    }
    
    func addQuestion(newQuestion: Question) {
        if (newQuestions.filter { $0.hint == newQuestion.hint }.count == 0
            && seenQuestions.filter { $0.hint == newQuestion.hint }.count == 0) {
            newQuestions.append(newQuestion)
        } else {
            print("question already exists")
        }
    }
    
    func getNextQuestion(lastQuestion: Question? = nil) -> Question {
        if let lastQuestion = lastQuestion {
            if (!newQuestions.isEmpty && newQuestions.first!.hint == lastQuestion.hint) {
                newQuestions.removeFirst()
            } else {
                seenQuestions.removeFirst()
            }
            seenQuestions.insert(lastQuestion, at: 0)
            seenQuestions = seenQuestions.sorted(by: { $0.timeToShow < $1.timeToShow } )
        }
        DispatchQueue.global(qos: .background).async {
            Ordlister.shared.saveQuestions()
        }
        
        if (newQuestions.isEmpty || (!seenQuestions.isEmpty && seenQuestions.first!.timeToShow < Date())) {
            return seenQuestions.first!
        }
        return newQuestions.first!
    }
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURLPreSuf = DocumentsDirectory.appendingPathComponent("questions")
    static let ArchiveURLCustomLists = DocumentsDirectory.appendingPathComponent("customQuestions")
    
    //NSCoding
    struct PropertyKey {
        static let newQuestions = "newQuestions"
        static let seenQuestions = "seenQuestions"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(newQuestions, forKey: PropertyKey.newQuestions)
        aCoder.encode(seenQuestions, forKey: PropertyKey.seenQuestions)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let newQuestions = aDecoder.decodeObject(forKey: PropertyKey.newQuestions) as! [Question]
        let seenQuestions = aDecoder.decodeObject(forKey: PropertyKey.seenQuestions) as! [Question]
        
        self.init(newQuestions: newQuestions, seenQuestions: seenQuestions)
    }
    
    
    
    
}
