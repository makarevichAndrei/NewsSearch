//
//  SearchNewsViewController.swift
//  NewsSearch
//
//  Created by Andrei on 1/26/19.
//  Copyright © 2019 makarevich. All rights reserved.
//

import UIKit
import CoreData

class SearchNewsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UISearchBarDelegate {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    struct Constants {
        static let newsCellReuseIdentifier = "NewsTableViewCell"
        static let searchItemCellReuseIdentifier = "SearchItemTableViewCell"
        static let detailsSegue = "NewsDetails"
    }
    
    private enum TableMode {
        case news
        case searchItems
    }
    
    private var tableMode: TableMode = .news
    private var service: NewsServiceProtocol = NewsService()
    private lazy var searchItemsResultsController: NSFetchedResultsController<SearchItem> = service.searchItemsResultsController()
    private var fetchedResultsController: NSFetchedResultsController<News>? {
        didSet{
            fetchedResultsController?.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        tableView.reloadData()
    }
    
    private func loadNews(for text: String?) {
        guard let text = text else {
            fetchedResultsController = nil
            tableView.reloadData()
            return
        }
        
        fetchedResultsController = service.newsFetchedResultsController(for: text)
        tableView.reloadData()
    }
    
    private func loadNews(with searchItem: SearchItem) {
        fetchedResultsController = service.newsFetchedResultsController(with: searchItem)
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        switch tableMode {
        case .news:
            return fetchedResultsController?.sections?.count ?? 0
        case .searchItems:
            return searchItemsResultsController.sections?.count ?? 0
        }
        
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableMode {
        case .news:
            return fetchedResultsController?.sections?[section].numberOfObjects ?? 0
        case .searchItems:
            return searchItemsResultsController.sections?[section].numberOfObjects ?? 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch tableMode {
        case .news:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.newsCellReuseIdentifier, for: indexPath) as! NewsTableViewCell
            
            guard let news = fetchedResultsController?.object(at: indexPath) else {
                return cell
            }
            
            cell.textLabel?.text = news.title
            
            if news.checked {
                cell.textLabel?.textColor = UIColor.blue
            }
            
            service.loadImage(news: news) { [weak self] image in
                guard self?.tableView.indexPathsForVisibleRows?.contains(indexPath) ?? false, let cell = self?.tableView.cellForRow(at: indexPath) as? NewsTableViewCell else {
                    return
                }
                
                cell.setPoster(image)
            }
            
            return cell
        case .searchItems:
            let cell = tableView.dequeueReusableCell(withIdentifier: Constants.searchItemCellReuseIdentifier, for: indexPath)
            cell.textLabel?.text = searchItemsResultsController.object(at: indexPath).searchText
            
            return cell
        }
        
        
    }
    
    // MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch tableMode {
        case .news:
            break
        case .searchItems:
            loadNews(with: searchItemsResultsController.object(at: indexPath))
            searchBar.resignFirstResponder()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableMode {
        case .news:
            return 70.0
        case .searchItems:
            return 44
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.detailsSegue, let viewController = segue.destination as? NewsViewController, let indexPath = tableView.indexPathForSelectedRow {
            let news = fetchedResultsController?.object(at: indexPath)
            viewController.setup(news: news, service: service)
        }
    }
    
    // MARK: Fetched Results Controller Delegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else {
                return
            }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete, .move, .update:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        tableMode = .searchItems
        tableView.reloadData()
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        tableMode = .news
        tableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        loadNews(for: searchBar.text)
        searchBar.text = nil
        searchBar.resignFirstResponder()
    }
}
