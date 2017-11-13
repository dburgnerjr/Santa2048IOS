//
//  ViewController.swift
//  Santa2048IOS
//
//  Created by Daniel Burgner on 11/12/17.
//  Copyright © 2017 Daniel Burgner. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func startGameButtonTapped(sender: UIButton) {
        let game = GameViewController(dimension: 4, threshold: 2048)
        self.presentViewController(game, animated: true, completion: nil)
    }
}

