//
//  Accessory.swift
//  Santa2048IOS
//
//  Created by Daniel Burgner on 11/12/17.
//  Copyright © 2017 Daniel Burgner. All rights reserved.
//

import UIKit

protocol ScoreViewProtocol {
    func scoreChanged(newScore s: Int)
}

class ScoreView : UIView, ScoreViewProtocol {
    var score: Int = 0 {
        didSet {
            label.text = "SCORE: \(score)"
        }
    }
    let defaultFrame = CGRect(origin: .zero, size: CGSize(width: 140, height: 140))
    var label: UILabel
    
    init(backgroundColoe bgcolor: UIColor, textColor tcolor:
        UIColor, font: UIFont, radius r: CGFloat) {
        label = UILabel(frame: defaultFrame)
        label.textAlignment = NSTextAlignment.center
        super.init(frame: defaultFrame)
        
        backgroundColor = bgcolor
        label.textColor = tcolor
        label.font = font
        
        layer.cornerRadius = r
        self.addSubview(label)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    func scoreChanged(newScore s: Int) {
        let defaultFrame = CGRect(origin: .zero, size: CGSize(width: 140, height: 140))
    }
}
