//
//  HistoryEntry.swift
//  MountainBrowser
//

import Foundation
import SwiftData

@Model
final class HistoryEntry {
    var title: String
    var urlString: String
    var visitDate: Date
    
    init(title: String, urlString: String, visitDate: Date = Date()) {
        self.title = title
        self.urlString = urlString
        self.visitDate = visitDate
    }
}
