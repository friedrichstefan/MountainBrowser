//
//  Bookmark.swift
//  AppleTVBrowser
//

import Foundation
import SwiftData

@Model
final class Bookmark {
    var title: String
    var urlString: String
    var dateAdded: Date
    var folder: BookmarkFolder?
    
    init(title: String, urlString: String, dateAdded: Date = Date(), folder: BookmarkFolder? = nil) {
        self.title = title
        self.urlString = urlString
        self.dateAdded = dateAdded
        self.folder = folder
    }
}
