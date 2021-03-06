//
//  Question.swift
//  ordbok
//
//  Created by Kim Stephen Bovim on 11/10/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import Foundation

class Question: NSObject, Codable, NSCoding {
    let hint: String
    let answer: [String]
    let hintScore: Int
    var timeToShow: Date
    var daysToAdd: Int
    var lastShown: Date?
    
    init(hint: String, answer: [String], hintScore: Int, timeToShow: Date = Date.distantFuture, daysToAdd: Int = 7, lastShown: Date? = nil) {
        self.hint = hint
        self.answer = answer
        self.hintScore = hintScore
        self.timeToShow = timeToShow
        self.daysToAdd = daysToAdd
        self.lastShown = lastShown
    }
    
    func setTimeToShow(answeredCorrect: Bool) {
        lastShown = Date()
        if (answeredCorrect) {
            timeToShow = Calendar.current.date(byAdding: .day, value: daysToAdd, to: Date())!
            daysToAdd *= 2
        } else {
            timeToShow = Date()
            daysToAdd = 3
        }
    }
    
    //NSCoding
    struct PropertyKey {
        static let hint = "hint"
        static let answer = "answer"
        static let hintScore = "hintScore"
        static let timeToShow = "timeToShow"
        static let daysToAdd = "daysToAdd"
        static let lastShown = "lastShown"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(hint, forKey: PropertyKey.hint)
        aCoder.encode(answer, forKey: PropertyKey.answer)
        aCoder.encode(hintScore, forKey: PropertyKey.hintScore)
        aCoder.encode(timeToShow, forKey: PropertyKey.timeToShow)
        aCoder.encode(daysToAdd, forKey: PropertyKey.daysToAdd)
        aCoder.encode(lastShown, forKey: PropertyKey.lastShown)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let hint = aDecoder.decodeObject(forKey: PropertyKey.hint) as! String
        let answer = aDecoder.decodeObject(forKey: PropertyKey.answer) as! [String]
        let hintScore = aDecoder.decodeInteger(forKey: PropertyKey.hintScore)
        let timeToShow = aDecoder.decodeObject(forKey: PropertyKey.timeToShow) as! Date
        let daysToAdd = aDecoder.decodeInteger(forKey: PropertyKey.daysToAdd)
        let lastShown = aDecoder.decodeObject(forKey: PropertyKey.lastShown) as? Date
        
        self.init(hint: hint, answer: answer, hintScore: hintScore, timeToShow: timeToShow, daysToAdd: daysToAdd, lastShown: lastShown)
    }
}
