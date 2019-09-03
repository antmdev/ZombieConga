//
//  GameViewController.swift
//  ZombieConga
//
//  Created by Ant Milner on 25/08/2019.
//  Copyright © 2019 Ant Milner. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let scene = GameScene(size:CGSize (width: 2048, height: 1536))
     //   let scene = MainMenuScene(size:CGSize (width: 2688, height: 1242)) //iphone xs max
        let skView = self.view as! SKView
        skView.showsFPS = true
        skView.showsNodeCount = true
        skView.ignoresSiblingOrder = true
        scene.scaleMode = .aspectFill
//        scene.scaleMode = .resizeFill //might help on iphone XS MAX
        skView.presentScene(scene)
    }
    
    override var prefersStatusBarHidden: Bool
        {
        return true
        }
}
