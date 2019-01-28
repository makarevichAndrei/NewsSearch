//
//  NewsTableViewCell.swift
//  NewsSearch
//
//  Created by Andrei on 1/27/19.
//  Copyright © 2019 makarevich. All rights reserved.
//

import UIKit

class NewsTableViewCell: UITableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func prepareForReuse() {
        imageView?.image = UIImage(named: "placeholder.png")
        textLabel?.text = nil
        textLabel?.textColor = UIColor.black
    }
    
    func setPoster(_ image: UIImage) {
        imageView?.image = image
    }
    
    override func layoutSubviews() {
        let imageFrame = CGRect(x: 8, y: 1, width: frame.height * 2, height: frame.height - 2)
        imageView?.frame = imageFrame
        let positionX = imageFrame.origin.x + imageFrame.width + 16
        textLabel?.frame = CGRect(x: positionX, y: 1 , width: frame.width - positionX - 8, height: frame.height - 2)
    }

}
