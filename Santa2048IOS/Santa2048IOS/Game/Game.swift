//
//  Game.swift
//  Santa2048IOS
//
//  Created by Daniel Burgner on 11/12/17.
//  Copyright © 2017 Daniel Burgner. All rights reserved.
//

import UIKit

class GameViewController : UIViewController, GameModelProtocol {
    func scoreChange(score: Int) {
        if scoreView == nil {
            return
        }
        let s = scoreView!
        s.scoreChanged(newScore: score)
    }
    
    func moveTwoTile(from: ((Int, Int), (Int, Int)), to: (Int, Int), value: Int) {
        assert(board != nil)
        let b = board!
        moveTwoTile(from: from, to: to, value: value)
    }
    
    var dimension: Int
    var threshold: Int
    
    var board: Board?
    var model: GameModel?
    
    var scoreView: ScoreViewProtocol?
    
    let boardWidth: CGFloat = 230.0
    let thinPadding: CGFloat = 3.0
    let thickPadding: CGFloat = 6.0
    let viewPadding: CGFloat = 10.0
    let verticalViewOffset: CGFloat = 0.0
    
    init(dimension d: Int, threshold t: Int) {
        dimension = d > 2 ? d : 2
        threshold = t > 8 ? t : 8
        super.init(nibName: nil, bundle: nil)
        model = GameModel(dimension: dimension, threshold: threshold, delegate: self)
        view.backgroundColor = UIColor(red: 131.0/255.0, green: 3.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        setupSwipeControls()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    func setupSwipeControls() {
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.upCommand(r:)))
        upSwipe.numberOfTouchesRequired = 1
        upSwipe.direction = UISwipeGestureRecognizerDirection.up
        view.addGestureRecognizer(upSwipe)
        
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.downCommand(r:)))
        downSwipe.numberOfTouchesRequired = 1
        downSwipe.direction = UISwipeGestureRecognizerDirection.down
        view.addGestureRecognizer(downSwipe)
        
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.leftCommand(r:)))
        leftSwipe.numberOfTouchesRequired = 1
        leftSwipe.direction = UISwipeGestureRecognizerDirection.left
        view.addGestureRecognizer(leftSwipe)
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(GameViewController.rightCommand(r:)))
        rightSwipe.numberOfTouchesRequired = 1
        rightSwipe.direction = UISwipeGestureRecognizerDirection.right
        view.addGestureRecognizer(rightSwipe)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGame()
    }
    
    func reset() {
        assert(board != nil && model != nil)
        let b = board!
        let m = model!
        b.reset()
        m.reset()
        m.insertTileAtRandomLocation(value: 2)
        m.insertTileAtRandomLocation(value: 2)
    }
    
    func setupGame() {
        let vcHeight = view.bounds.size.height
        let vcWidth = view.bounds.size.width
        
        func xPositionToCenterView(v: UIView) -> CGFloat {
            let viewWidth = v.bounds.size.width
            let tentativeX = 0.5*(vcWidth - viewWidth)
            return tentativeX >= 0 ? tentativeX : 0
        }
        
        func yPositionForViewAtPosition(order: Int, views: [UIView]) -> CGFloat {
            assert(views.count > 0)
            assert(order >= 0 && order < views.count)
            let viewHeight = views[order].bounds.size.height
            let totalHeight = CGFloat(views.count - 1) * viewPadding + views.map({ $0.bounds.size.height }).reduce(verticalViewOffset, { $0 + $1 })
            let viewsTop = 0.5 * (vcHeight - totalHeight) >= 0 ? 0.5 * (vcHeight - totalHeight) : 0
            
            var acc: CGFloat = 0
            for i in 0..<order {
                acc += viewPadding + views[i].bounds.size.height
            }
            return viewsTop + acc
        }
        
        let scoreView = ScoreView(backgroundColor: UIColor.black, textColor: UIColor.white, font: UIFont(name: "HelveticaNeue-Bold", size: 16.0) ?? UIFont.systemFont(ofSize: 16.0), radius: 6)
        scoreView.score = 0
        
        // create the gameboard
        let padding: CGFloat = dimension > 5 ? thinPadding : thickPadding
        let v1 = boardWidth - padding * (CGFloat(dimension + 1))
        let width: CGFloat = CGFloat(floorf(CFloat(v1)))/CGFloat(dimension)
        let gameboard = Board(dimension: dimension,
                              tileWidth: width,
                              tilePadding: padding,
                              cornerRadius: 6,
                              backgroundColor: UIColor.black,
                              foregroundColor: UIColor.darkGray)
        
        let views = [scoreView, gameboard]
        
        var f = scoreView.frame
        f.origin.x = xPositionToCenterView(v: scoreView)
        f.origin.y = yPositionForViewAtPosition(order: 0, views: views)
        scoreView.frame = f
        
        f = gameboard.frame
        f.origin.x = xPositionToCenterView(v: gameboard)
        f.origin.y = yPositionForViewAtPosition(order: 1, views: views)
        scoreView.frame = f
        
        view.addSubview(gameboard)
        board = gameboard
        view.addSubview(scoreView)
        self.scoreView = scoreView
        
        assert(model != nil)
        let m = model!
        m.insertTileAtRandomLocation(value: 2)
        m.insertTileAtRandomLocation(value: 2)
    }
    
    // Misc
    func followUp() {
        assert(model != nil)
        let m = model!
        let (userWon, winningCoords) = m.userHasWon()
        if userWon {
            let alertView = UIAlertController()
            alertView.title = "Victory"
            alertView.message = "You won!"
            alertView.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alertView, animated: true, completion: nil)
            return
        }
        
        let randomVal = Int(arc4random_uniform(10))
        m.insertTileAtRandomLocation(value: randomVal == 1 ? 4 : 2)
        
        if m.userHasLost() {
            NSLog("You lost...")
            let alertView = UIAlertController()
            alertView.title = "Defeat"
            alertView.message = "You lost..."
            alertView.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            self.present(alertView, animated: true, completion: nil)
            return
        }
    }
    
    @objc(up:)
    func upCommand(r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(direction: MoveDirection.Up,
                    completion: { (changed: Bool) -> () in
                        if changed {
                            self.followUp()
                        }
        })
    }
    
    @objc(down:)
    func downCommand(r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(direction: MoveDirection.Down,
                    completion: { (changed: Bool) -> () in
                        if changed {
                            self.followUp()
                        }
        })
    }
    
    @objc(left:)
    func leftCommand(r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(direction: MoveDirection.Left,
                    completion: { (changed: Bool) -> () in
                        if changed {
                            self.followUp()
                        }
        })
    }
    
    @objc(right:)
    func rightCommand(r: UIGestureRecognizer!) {
        assert(model != nil)
        let m = model!
        m.queueMove(direction: MoveDirection.Right,
                    completion: { (changed: Bool) -> () in
                        if changed {
                            self.followUp()
                        }
        })
    }
    
    func moveOneTile(from: (Int, Int), to: (Int, Int), value: Int) {
        assert(board != nil)
        let b = board!
        moveOneTile(from: from, to: to, value: value)
    }
    
    func insertTile(location: (Int, Int), value: Int) {
        assert(board != nil)
        let b = board!
        insertTile(location: location, value: value)
    }
}
