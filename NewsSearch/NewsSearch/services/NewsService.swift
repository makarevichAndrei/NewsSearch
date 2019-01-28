//
//  NewsService.swift
//  NewsSearch
//
//  Created by Andrei on 1/26/19.
//  Copyright © 2019 makarevich. All rights reserved.
//

import Foundation
import CoreData
import UIKit

protocol NewsServiceProtocol {
    func newsFetchedResultsController(for searchText: String) -> NSFetchedResultsController<News>?
    func newsFetchedResultsController(with searchItem: SearchItem) -> NSFetchedResultsController<News>
    func searchItemsResultsController() -> NSFetchedResultsController<SearchItem>
    func setViewed(news: News)
    func loadImage(news: News, complition: @escaping (UIImage) -> Void)
}

class NewsService: NewsServiceProtocol {
    
    func newsFetchedResultsController(for searchText: String) -> NSFetchedResultsController<News>? {
        let searchItem: SearchItem
        if let existingSearchItem = fetchSearchItem(with: searchText) {
            searchItem = existingSearchItem
        } else {
            let context = CoreDataStack.shared.persistentContainer.viewContext
            guard let newSearchItem = NSEntityDescription.insertNewObject(forEntityName: String(describing: SearchItem.self), into: context) as? SearchItem else {
                print("Cannot creat SearchItem")
                return nil
            }
            searchItem = newSearchItem
        }
        searchItem.searchText = searchText
        searchItem.date = NSDate()
        
        loadNews(with: searchItem)
        return fetchedResultsController(with: searchItem)
    }
    
    func newsFetchedResultsController(with searchItem: SearchItem) -> NSFetchedResultsController<News> {
        updateSearchDate(searchItem: searchItem)
        loadNews(with: searchItem)
        return fetchedResultsController(with: searchItem)
    }
    
    func searchItemsResultsController() -> NSFetchedResultsController<SearchItem> {
        let fetchRequest: NSFetchRequest<SearchItem> = SearchItem.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(SearchItem.date), ascending: false)]
        fetchRequest.fetchLimit = 5
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Cannot perfor search items fetch")
        }
        return fetchedResultsController
    }
    
    func loadImage(news: News, complition: @escaping (UIImage) -> Void) {
        guard let imageUrlString = news.urlToImage, let imageUrl = URL(string: imageUrlString) else {
            return
        }
        
        let session = URLSession(configuration: .default)
        
        let dataTask = session.dataTask(with: imageUrl) { data, response, error in
            guard error == nil,
                let data = data,
                let image = UIImage(data: data) else {
                print("Cannot load or create image from: \(imageUrlString)")
                return
            }
            DispatchQueue.main.async {
                complition(image)
            }
        }
        dataTask.resume()
        
    }
    
    func setViewed(news: News) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        news.checked = true;
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                context.reset()
                print("Cannot save context.")
            }
        }
    }
    
    private func fetchedResultsController(with searchItem: SearchItem) -> NSFetchedResultsController<News> {
        let fetchRequest: NSFetchRequest<News> = News.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(News.publishedAt), ascending: false)]
        fetchRequest.predicate = NSPredicate(format: "\(#keyPath(News.searchItem.searchText)) = %@", searchItem.searchText)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("Cannot perfor news fetch")
        }
        return fetchedResultsController
    }
    
    private func loadNews(with searchItem: SearchItem) {
        let path = String(format: "https://newsapi.org/v2/top-headlines?q=%@&apiKey=b59bc1f13f884301a259ebc4a7c68af2", searchItem.searchText)
        guard let url = URL(string: path) else {
            print("Cannot creat URL")
            return
        }
        let session = URLSession(configuration: .default)
        
        let dataTask = session.dataTask(with: url) { [weak self] data, response, error in
            guard error == nil else {
                print("Cannot load news. Error: \(error?.localizedDescription ?? "unnown")")
                return
            }
            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String: Any], let articles = json["articles"] as? [[String: Any]] else {
                print("Cannot deserialize data")
                return
            }
            
            print("\(articles)")
            
            self?.parseAndSaveNews(articles: articles, searchItem: searchItem)
        }
        dataTask.resume()
    }
    
    private func parseAndSaveNews(articles: [[String: Any]], searchItem: SearchItem) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        var newsSet = Set<News>()
        
        for articale in articles {
            guard let title = articale["title"] as? String else {
                continue
            }
            
            var news: News
            
            if let existingNews = fetchNews(with: title, searchItem: searchItem, context: context) {
                news = existingNews
            } else {
                guard let newNews = NSEntityDescription.insertNewObject(forEntityName: String(describing: News.self), into: context) as? News else {
                    print("Cannot create News item")
                    return
                }
                news = newNews
            }
            
            news.searchItem = searchItem
            news.title = title
            news.author = articale["author"] as? String
            news.url = articale["url"] as? String
            news.content = articale["content"] as? String
            news.urlToImage = articale["urlToImage"] as? String
            news.newsDescription = articale["description"] as? String
            
            if let dateString = articale["publishedAt"] as? String, let date = dateFormatter.date(from: dateString) {
                
                news.publishedAt = date as NSDate
            } else {
                news.publishedAt = nil
            }
            
            newsSet.insert(news)
        }
        
        searchItem.addToNews(newsSet as NSSet)
        
        if context.hasChanges {
            
            do {
                try context.save()
                print("news saved")
            } catch {
                context.reset()
                print("Cannot save news items.")
            }
        }
    }
    
    private func fetchNews(with title: String, searchItem: SearchItem, context: NSManagedObjectContext) -> News? {
        let fetchRequest: NSFetchRequest<News> = News.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(#keyPath(News.title)) = %@ AND \(#keyPath(News.searchItem.searchText)) = %@", title, searchItem.searchText)
        let result = try? context.fetch(fetchRequest) as [News]
        return result?.first
    }
    
    private func fetchSearchItem(with text: String) -> SearchItem? {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<SearchItem> = SearchItem.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "\(#keyPath(SearchItem.searchText)) = %@", text)
        let result = try? context.fetch(fetchRequest) as [SearchItem]
        return result?.first
    }
    
    private func updateSearchDate(searchItem: SearchItem) {
        let context = CoreDataStack.shared.persistentContainer.viewContext
        searchItem.date = NSDate()
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                context.reset()
                print("Cannot save context.")
            }
        }
    }
}
