//
//  DawgBuilder.swift
//  Dawg
//
//  Created by Chris Nevin on 25/06/2016.
//  Copyright © 2016 CJNevin. All rights reserved.
//

import Foundation
import UIKit

func == (lhs: DawgBuilderNode, rhs: DawgBuilderNode) -> Bool {
    return lhs.descr == rhs.descr
}

class DawgBuilderNode: CustomStringConvertible, Hashable, CustomDebugStringConvertible {
    typealias Edges = [DawgLetter: DawgBuilderNode]

    fileprivate static var nextId: UInt32 = 0
    fileprivate var descr: String = ""
    lazy var edges = Edges()
    var final: Bool = false
    var id: UInt32
    
    /// Create a new node while building a new Dawg.
    init() {
        self.id = type(of: self).nextId
        type(of: self).nextId += 1
        updateDescription()
    }
    
    /// Create a new node with existing data into an existing Dawg.
    /// - parameter id: Node identifier.
    /// - parameter final: Whether this node terminates a word.
    init(withId id: UInt32, final: Bool) {
        type(of: self).nextId = max(type(of: self).nextId, id)
        self.id = id
        self.final = final
    }
    
    func updateDescription() {
        var arr = [final ? "1" : "0"]
        arr.append(contentsOf: edges.map({ "\($0.0)_\($0.1.id)" }))
        descr = arr.joined(separator: "_")
    }
    
    func setEdge(_ letter: DawgLetter, node: DawgBuilderNode) {
        edges[letter] = node
        updateDescription()
    }
    
    var description: String {
        return descr
    }
    
    var debugDescription: String {
        return "id: \(id), final: \(final)"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(descr.hashValue)
    }
}
