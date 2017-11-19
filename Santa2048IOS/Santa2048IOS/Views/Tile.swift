//
//  Tile.swift
//  Santa2048IOS
//
//  Created by Daniel Burgner on 11/12/17.
//  Copyright © 2017 Daniel Burgner. All rights reserved.
//

import UIKit

class Tile: UIView {
    var delegate: AppearanceProtocol
    var value: Int = 0 {
        didSet {
            backgroundColor = delegate.tileColor(value: value)
            numberLabel = delegate.numberColor(value: value)
            numberLabel.text = "\(value)"
        }
    }
    var numberLabel: UILabel
    
    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    init(position: CGPoint, width: CGFloat, value: Int, radius: CGFloat,
         delegate d: AppearanceProtocol) {
        
        delegate = d
        numberLabel = UILabel(frame: CGRect(origin: CGPoint(x: 0,y: 0), size: CGSize(width: width, height: width)))
        numberLabel.textAlignment = NSTextAlignment.center
        numberLabel.minimumScaleFactor = 0.5
        numberLabel.font = delegate.fontForNumbers()
        
        super.init(frame: CGRect(origin: CGPoint(x: 0,y: 0), size: CGSize(width: width, height: width)))
        addSubview(numberLabel)
        layer.cornerRadius = radius
        
        self.value = value
        backgroundColor = delegate.tileColor(value: value)
        numberLabel.textColor = delegate.numberColor(value: value)
        numberLabel.text = "\(value)"
    }
}
