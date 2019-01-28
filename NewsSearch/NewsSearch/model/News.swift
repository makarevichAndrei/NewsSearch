//
//  News.swift
//  NewsSearch
//
//  Created by Andrei on 1/26/19.
//  Copyright © 2019 makarevich. All rights reserved.
//
//

import Foundation
import CoreData


@objc(News)
public class News: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<News> {
        return NSFetchRequest<News>(entityName: String(describing: News.self))
    }

    @NSManaged public var content: String?
    @NSManaged public var author: String?
    @NSManaged public var newsDescription: String?
    @NSManaged public var publishedAt: NSDate?
    @NSManaged public var title: String
    @NSManaged public var url: String?
    @NSManaged public var urlToImage: String?
    @NSManaged public var searchItem: SearchItem?
    @NSManaged public var checked: Bool

}
