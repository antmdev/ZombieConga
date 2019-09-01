//
//  GameOverScene.swift
//  ZombieConga
//
//  Created by Ant Milner on 31/08/2019.
//  Copyright © 2019 Ant Milner. All rights reserved.
//

import Foundation
import SpriteKit

class GameOverScene: SKScene {
 
/*****************************************************
 SCENE CONSTANTS
 ******************************************************/
    
    let won:Bool // boolean status of win / lose

    
    
/*****************************************************
INITIALISE PLAYABLE AREA
******************************************************/
    
    // custom initializer that takes just one extra parameter (Status win / lose)
    init(size: CGSize, won: Bool)
    {
        self.won = won
        super.init(size: size)
    }
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

/*****************************************************
 DID MOVE FUNCTION BACKGROUND
 ******************************************************/


override func didMove(to view: SKView)
{
    var background: SKSpriteNode
    if (won)
    {
        background = SKSpriteNode(imageNamed: "YouWin")
        run(SKAction.playSoundFileNamed("win.wav", waitForCompletion: false))
    }
    else
    {
        background = SKSpriteNode(imageNamed: "YouLose")
        run(SKAction.playSoundFileNamed("lose.wav",
        waitForCompletion: false))
    }
    
    background.position = CGPoint(x: size.width/2, y: size.height/2)
    self.addChild(background)
  
    //ANIMATION FOR GAME OVER SCENE
    
    let wait = SKAction.wait(forDuration: 3.0)
    let block = SKAction.run
    {
        let myScene = GameScene(size: self.size)
        myScene.scaleMode = self.scaleMode
        let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
        self.view?.presentScene(myScene, transition: reveal)
    }
    self.run(SKAction.sequence([wait, block]))
}

    
} //CLOSING CLASS BRACKET
