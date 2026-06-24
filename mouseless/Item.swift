//
//  Item.swift
//  mouseless
//
//  Created by Snehil on 24/06/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
