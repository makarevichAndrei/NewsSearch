//
//  NewsViewController.swift
//  NewsSearch
//
//  Created by Andrei on 1/27/19.
//  Copyright © 2019 makarevich. All rights reserved.
//

import UIKit

class NewsViewController: UIViewController {
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var publishDateLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet weak var urlText: UITextView!
    
    private var news: News?
    private var service: NewsServiceProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = news?.title
        
        if let date = news?.publishedAt as Date? {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .long
            let dateString = dateFormatter.string(from: date)
            publishDateLabel.text = "published at: " + dateString
        }
        descriptionLabel.text = news?.newsDescription
        urlText.text = news?.url
        
        guard let news = news else {
            return
        }
        service?.loadImage(news: news) { [weak self] image in
            self?.imageView.image = image
            self?.loadViewIfNeeded()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let news = news else {
            return
        }
        service?.setViewed(news: news)
    }
    
    func setup(news: News?, service: NewsServiceProtocol) {
        self.news = news
        self.service = service
    }
}
