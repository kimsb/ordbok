//
//  WorkoutSettings.swift
//  ordbok
//
//  Created by Kim Stephen Bovim on 13/10/2019.
//  Copyright © 2019 Kim Stephen Bovim. All rights reserved.
//

import Foundation

class WorkoutSettings: NSObject, Codable, NSCoding {
    var presufBaseCountSelect: Int
    var presufModeSelect: Int
    var presufExclusiveSelect: Int
    var presufOrListsSelect: Int
    
    init(presufBaseCountSelect: Int, presufModeSelect: Int, presufExclusiveSelect: Int, presufOrListsSelect: Int) {
        self.presufBaseCountSelect = presufBaseCountSelect
        self.presufModeSelect = presufModeSelect
        self.presufExclusiveSelect = presufExclusiveSelect
        self.presufOrListsSelect = presufOrListsSelect
    }
    
    //MARK: Archiving Paths
    static let DocumentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
    static let ArchiveURL = DocumentsDirectory.appendingPathComponent("WorkoutSettings")
    
    //NSCoding
    struct PropertyKey {
        static let presufBaseCountSelect = "presufBaseCountSelect"
        static let presufModeSelect = "presufModeSelect"
        static let presufExclusiveSelect = "presufExclusiveSelect"
        static let presufOrListsSelect = "presufOrListsSelect"
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(presufBaseCountSelect, forKey: PropertyKey.presufBaseCountSelect)
        aCoder.encode(presufModeSelect, forKey: PropertyKey.presufModeSelect)
        aCoder.encode(presufExclusiveSelect, forKey: PropertyKey.presufExclusiveSelect)
        aCoder.encode(presufOrListsSelect, forKey: PropertyKey.presufOrListsSelect)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let presufBaseCountSelect = aDecoder.decodeInteger(forKey: PropertyKey.presufBaseCountSelect)
        let presufModeSelect = aDecoder.decodeInteger(forKey: PropertyKey.presufModeSelect)
        let presufExclusiveSelect = aDecoder.decodeInteger(forKey: PropertyKey.presufExclusiveSelect)
        let presufOrListsSelect = aDecoder.decodeInteger(forKey: PropertyKey.presufOrListsSelect)
        
        self.init(presufBaseCountSelect: presufBaseCountSelect, presufModeSelect: presufModeSelect, presufExclusiveSelect: presufExclusiveSelect, presufOrListsSelect: presufOrListsSelect)
    }
    
}
