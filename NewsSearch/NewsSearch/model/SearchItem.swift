//
//  SearchItem.swift
//  NewsSearch
//
//  Created by Andrei on 1/26/19.
//  Copyright © 2019 makarevich. All rights reserved.
//
//

import Foundation
import CoreData


@objc(SearchItem)
public class SearchItem: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SearchItem> {
        return NSFetchRequest<SearchItem>(entityName: String(describing: SearchItem.self))
    }

    @NSManaged public var searchText: String
    @NSManaged public var date: NSDate
    @NSManaged public var news: NSSet?

}

// MARK: Generated accessors for news
extension SearchItem {

    @objc(addNewsObject:)
    @NSManaged public func addToNews(_ value: News)

    @objc(removeNewsObject:)
    @NSManaged public func removeFromNews(_ value: News)

    @objc(addNews:)
    @NSManaged public func addToNews(_ values: NSSet)

    @objc(removeNews:)
    @NSManaged public func removeFromNews(_ values: NSSet)

}
