//
//  BookmarkFolder.swift
//  AppleTVBrowser
//

import Foundation
import SwiftData

@Model
final class BookmarkFolder {
    var name: String
    var dateCreated: Date
    @Relationship(deleteRule: .cascade, inverse: \Bookmark.folder)
    var bookmarks: [Bookmark]
    
    init(name: String, dateCreated: Date = Date(), bookmarks: [Bookmark] = []) {
        self.name = name
        self.dateCreated = dateCreated
        self.bookmarks = bookmarks
    }
}
