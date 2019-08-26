//
//  GameScene.swift
//  ZombieConga
//
//  Created by Ant Milner on 25/08/2019.
//  Copyright © 2019 Ant Milner. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene
{
  
//GAME CONSTANTS
    
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0 // zombie should move around 1/4 of screen in 1 second
    var velocity = CGPoint.zero
    
///////////VIEW///////////
    override func didMove(to view: SKView)
    {
        
// BACKGROUND
        backgroundColor = SKColor.black
        let background = SKSpriteNode(imageNamed: "background1")
//        background.position = CGPoint(x: size.width/2, y: size.height/2)
//        background.anchorPoint = CGPoint.zero
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5) //default
        background.position = CGPoint(x: size.width/2, y: size.height/2)
//        background.zRotation = CGFloat.pi / 8
        background.zPosition = -1 //ensure background is behind all sprites
        addChild(background)
        let mySize = background.size
        print("Size: \(mySize)")
        
        
// SPRITE
        zombie.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        zombie.position = CGPoint(x:400, y: 400)
//        zombie1.setScale(2) // SKNode method
        addChild(zombie)
        
    }
    
///////////UPDATE VIEW///////////
    override func update(_ currentTime: TimeInterval)
    {
//property to see difference between update times in FPS
        if lastUpdateTime > 0
        {
            dt = currentTime - lastUpdateTime
        } else
        {
        dt = 0
        }
        
        lastUpdateTime = currentTime
// passes in velocity (updated based on the touch) 
        move(sprite: zombie, velocity: velocity)
//        move(sprite: zombie, velocity: CGPoint(x: zombieMovePointsPerSec, y: 0))
        print("\(dt*1000) milliseconds since last update")
    }
    
// SPRITE MOVEMENT
    func move(sprite: SKSpriteNode, velocity: CGPoint)
    {
        // 1
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),
                                   y: velocity.y * CGFloat(dt))
        print("Amount to move: \(amountToMove)")
        // 2
        sprite.position = CGPoint(
            x: sprite.position.x + amountToMove.x,
            y: sprite.position.y + amountToMove.y)
    }
 // SPRITE OFFSET MOVEMENT
    func moveZombieToward(location: CGPoint)
    {

        let offset = CGPoint(x: location.x - zombie.position.x, y: location.y - zombie.position.y)
        let length = sqrt(Double(offset.x * offset.x + offset.y * offset.y))
        
        //normalise the vector so that it becomes a unit vector (i.e moves somewhere)
        let direction = CGPoint(x: offset.x / CGFloat(length), y: offset.y / CGFloat(length))
        velocity = CGPoint(x: direction.x * zombieMovePointsPerSec, y: direction.y * zombieMovePointsPerSec)
    }
    
 // TOUCH CONTROLS MOVEMENT
//    This will update the zombie’s velocity direction so that it points wherever the user taps the screen.
    
    func sceneTouched(touchLocation:CGPoint)
    {
        moveZombieToward(location: touchLocation)
    }
    // Tells this object that one or more new touches occurred in a view or window.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch = touches.first else
        {
            return
        }
        
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    //Tells the responder when one or more touches associated with an event changed.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch = touches.first else
        {
            return
        }
        
        let touchLocation = touch.location(in: self)
        sceneTouched(touchLocation: touchLocation)
    }
    
    

}





