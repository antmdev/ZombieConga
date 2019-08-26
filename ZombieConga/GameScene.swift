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
  
/*****************************************************
GAME CONSTANTS
******************************************************/
 
    
    let zombie = SKSpriteNode(imageNamed: "zombie1")
    var lastUpdateTime: TimeInterval = 0
    var dt: TimeInterval = 0
    let zombieMovePointsPerSec: CGFloat = 480.0 // zombie should move around 1/4 of screen in 1 second
    var velocity = CGPoint.zero
    let playableRect: CGRect                    //store the playable area
    
    
/*****************************************************
INITIALISE PLAYABLE AREA
******************************************************/

    override init(size: CGSize)
    {
        let maxAspectRatio:CGFloat = 16.0/9.0 // 1 make a constant for the maximum aspect ratio supported, 16:9
        let playableHeight = size.width / maxAspectRatio // 2  With aspect fill and a scene that is 2048x1536, the playable width will always be equal to the scene width, regardless of aspect ratio. To calculate the playable height, you divide the scene width by the maximum aspect ratio.
        let playableMargin = (size.height-playableHeight)/2.0 // 3 You want to center the playable rectangle on the screen, so you determine the margin on the top and bottom by subtracting the playable height from the scene height and dividing the result by 2.
        playableRect = CGRect(x: 0, y: playableMargin,
                              width: size.width,
                              height: playableHeight)
        // 4   You put it all together to make a rectangle with the maximum aspect ratio, centered on the screen.
        super.init(size: size) // 5 You call the initializer of the superclass.
    }
    
    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    // 6 Whenever you override the default initializer of a SpriteKit node, you must also override the required NSCoder initializer, which is used when you’re loading a scene from the scene editor. Since you’re not using the scene editor in this game, you simply add a placeholder implementation that logs an error.
    }
    
    func debugDrawPlayableArea() // add a helper method to draw this playable rectangle to the screen:
    {
        let shape = SKShapeNode()
        let path = CGMutablePath()
        path.addRect(playableRect)
        shape.path = path
        shape.strokeColor = SKColor.red
        shape.lineWidth = 4.0
        addChild(shape)
    }
        
/*****************************************************
BACKGROUND
 ******************************************************/
    
    override func didMove(to view: SKView)
    {
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
        zombie.position = CGPoint(x:400, y: 400)
//        zombie.anchorPoint = CGPoint(x: 0.5, y: 0.5)
//        zombie1.setScale(2) // SKNode method
        
        addChild(zombie)
        
        debugDrawPlayableArea() //call the debug playable area
        
    }
    
/*****************************************************
UPDATE VIEW
******************************************************/
    
    override func update(_ currentTime: TimeInterval)
    {
//property to see difference between update times in FPS
        if lastUpdateTime > 0
        {
            dt = currentTime - lastUpdateTime
        }
        else
        {
        dt = 0
        }
        
        lastUpdateTime = currentTime
        print("\(dt*1000) milliseconds since last update")

// passes in velocity (updated based on the touch)
        move(sprite: zombie, velocity: velocity)
//        move(sprite: zombie, velocity: CGPoint(x: zombieMovePointsPerSec, y: 0))
        
        boundsCheckZombie() //call method to bounce off walls

        
        rotate(sprite: zombie, direction: velocity)  //CALL ROTATION METHOD
    }

    
/*****************************************************
SPRITE MOVEMENT
******************************************************/
    func move(sprite: SKSpriteNode, velocity: CGPoint)
    {
        // 1
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt), y: velocity.y * CGFloat(dt))
        print("Amount to move: \(amountToMove)")
        // 2
        sprite.position = CGPoint(
            x: sprite.position.x + amountToMove.x, y: sprite.position.y + amountToMove.y)
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
    
/*****************************************************
TOUCH CONTROLS MOVEMENT
******************************************************/
    
//    This will update the zombie’s velocity direction so that it points wherever the user taps the screen.
    
    func sceneTouched(touchLocation:CGPoint)
    {
        moveZombieToward(location: touchLocation)
    }
    
    // Tells this object that one or more new touches occurred in a view or window.
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch = touches.first
        
        else
        {
            return
        }
        
        let touchLocation = touch.location(in: self)
        
        sceneTouched(touchLocation: touchLocation)
    }
    
    //Tells the responder when one or more touches associated with an event changed.
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let touch = touches.first
            
        else
        {
            return
        }
        
        let touchLocation = touch.location(in: self)
        
        sceneTouched(touchLocation: touchLocation)
    }
    
    // CALCULATE ZOMBIE POSITION RELATIVE TO EDGE TO LET HIM BOUNCE OFF WALLS
    func boundsCheckZombie()
    {
        // make constants for the bottom-left and top-right coordinates of the scene.
        let bottomLeft = CGPoint(x: 0, y: playableRect.minY)
        let topRight = CGPoint(x: size.width, y: playableRect.maxY)
        
        // Then, you check the zombie’s position to see if it’s beyond or on any of the screen edges. If it is, you clamp the position and reverse the appropriate velocity component to make the zombie bounce in the opposite direction.
        if zombie.position.x <= bottomLeft.x
        {
            zombie.position.x = bottomLeft.x
            velocity.x = -velocity.x
        }
        if zombie.position.x >= topRight.x
        {
            zombie.position.x = topRight.x
            velocity.x = -velocity.x
        }
        if zombie.position.y <= bottomLeft.y
        {
            zombie.position.y = bottomLeft.y
            velocity.y = -velocity.y
        }
        if zombie.position.y >= topRight.y
        {
            zombie.position.y = topRight.y
            velocity.y = -velocity.y
        }
    }
    
    // ROTATE ZOMBIE
    func rotate(sprite: SKSpriteNode, direction: CGPoint)
    {
        sprite.zRotation = CGFloat(atan2(Double(direction.y), Double(direction.x)))
    }
    
    

}





