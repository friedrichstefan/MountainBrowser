//
//  Item.swift
//  AppleTVBrowser
//
//  Created by Friedrich, Stefan on 09.02.26.
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
