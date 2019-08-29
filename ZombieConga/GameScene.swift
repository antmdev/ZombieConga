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
    var lastTouchLocation: CGPoint?             //Setting a last touchlocation to stop the zombie moving
    let zombieRotateRadiansPerSec:CGFloat = 4.0 * π //help smoothing rotation
    let zombieAnimation: SKAction
    
    
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
        
        
///////////////////////////////
// ZOMBIE ANIMATION ACTION!!!
///////////////////////////////
        // 1 create an array that will store all of the textures to run in the animation.
        
        var textures:[SKTexture] = []
        
        // 2 loop that creates a string for each image name and then makes a texture object from each name using the SKTexture(imageNamed:) initializer.
        
        for i in 1...4 {
            textures.append(SKTexture(imageNamed: "zombie\(i)"))
        }
        
        // 3 frames 3 and 2 to the list
        
        textures.append(textures[2])
        textures.append(textures[1])
        
        // 4 create and run an action with animate
        
        zombieAnimation = SKAction.animate(with: textures,
                                           timePerFrame: 0.1)
        
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
        background.anchorPoint = CGPoint(x: 0.5, y: 0.5) //default
        background.position = CGPoint(x: size.width/2, y: size.height/2)
        background.zPosition = -1 //ensure background is behind all sprites
        addChild(background)
        
        let mySize = background.size
        print("Size: \(mySize)")
        
        
// SPRITE ZOMBIE
        zombie.position = CGPoint(x:400, y: 400)
        
        addChild(zombie)
        
//        zombie.run(SKAction.repeatForever(zombieAnimation)) //Runs the animation for the zombie
        
        debugDrawPlayableArea() //call the debug playable area

// SPRITE ENEMY SEQUENCE RUN
        //New SPawn enemy in randomised locatin function
        //create a sequence of calling spawnEnemy() and waiting two seconds, and repeat this sequence forever.
        //Note: You are using a weak reference to self here. Otherwise the closure passed to run(_ block:) will create a strong reference cycle and result in a memory leak.
        
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run()
            {
                [weak self] in self?.spawnEnemy()
            },
                SKAction.wait(forDuration: 2.0)])))
        
// SPRITE CATS SEQUENCE RUN
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run()
            {
                [weak self] in self?.spawnCat()
            },
                SKAction.wait(forDuration: 1.0)])))
        
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
//        print("\(dt*1000) milliseconds since last update")

// passes in velocity (updated based on the touch)
        move(sprite: zombie, velocity: velocity)
//        move(sprite: zombie, velocity: CGPoint(x: zombieMovePointsPerSec, y: 0))
        
//ADDING A SETTING TO STOP THE ZOMBIE FROM MOVING AFTER CLICKING
        
        if let lastTouchLocation = lastTouchLocation
        {
            let diff = lastTouchLocation - zombie.position
            if diff.length() <= zombieMovePointsPerSec * CGFloat(dt)
            {
                zombie.position = lastTouchLocation
                velocity = CGPoint.zero
                stopZombieAnimation() //STOPS zombie animation after movement

            } else
            {
                move(sprite: zombie, velocity: velocity)
                rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)
            }
        }
        
        boundsCheckZombie() //call method to bounce off walls
        
    }

    
/*****************************************************
SPRITE MOVEMENT
******************************************************/
    
//    NEW CODE USING MATHS LIBRARY
    
    func move(sprite: SKSpriteNode, velocity: CGPoint)
    {
        let amountToMove = velocity * CGFloat(dt)
//        print("Amount to move: \(amountToMove)")
        sprite.position += amountToMove
    }
 
    // SPRITE OFFSET MOVEMENT
    func moveZombieToward(location: CGPoint)
    {
        startZombieAnimation() //calls the zombie animation function
        
        let offset = location - zombie.position
        let direction = offset.normalized()
        velocity = direction * zombieMovePointsPerSec
    }
    
/*****************************************************
TOUCH CONTROLS MOVEMENT
******************************************************/
    
//    This will update the zombie’s velocity direction so that it points wherever the user taps the screen.
    
    func sceneTouched(touchLocation:CGPoint)
    {
        lastTouchLocation = touchLocation //stopping zombie
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

    //Rotate Zombie
    func rotate(sprite: SKSpriteNode, direction: CGPoint, rotateRadiansPerSec: CGFloat)
    {
        let shortest = shortestAngleBetween(angle1: sprite.zRotation, angle2: velocity.angle)
        let amountToRotate = min(rotateRadiansPerSec * CGFloat(dt), abs(shortest))
        sprite.zRotation += shortest.sign() * amountToRotate
    }
    
/*****************************************************
 SPAWN ENEMY
 ******************************************************/
    
    func spawnEnemy()
    {
        let enemy = SKSpriteNode(imageNamed: "enemy")
        enemy.position = CGPoint(
            x: size.width + enemy.size.width/2,
            //modified the fixed y-position to be a random value between the bottom and top of the playable rectangle
            y: CGFloat.random(
                min: playableRect.minY + enemy.size.height/2,
                max: playableRect.maxY - enemy.size.height/2))
        addChild(enemy)
        
        let actionMove = SKAction.moveTo(x: -enemy.size.width/2, duration: 2.0)
      
        //REMOVE NODES ONCE THEY'RE NOT REQUIRED
        let actionRemove = SKAction.removeFromParent()
        //RUN SEQUENCE
        enemy.run(SKAction.sequence([actionMove, actionRemove]))
    }
  
/*****************************************************
 ZOMBIE ANIMATION ACTION!!
 ******************************************************/
    
    func startZombieAnimation() //tags animations with a Key called animation
    {
        if zombie.action(forKey: "animation") == nil // uses forKey - to check another version of animation isn't already running
        {
            zombie.run(SKAction.repeatForever(zombieAnimation),
                withKey: "animation")
        }
        
    }
    func stopZombieAnimation() //stops the zombie animation by removing the action
    {
        zombie.removeAction(forKey: "animation")
    }
    
/*****************************************************
 SCALE ACTION SPAWN CATS
 ******************************************************/
    func spawnCat() //spawn cat  in random positions accross max playable area
    {
        let cat = SKSpriteNode(imageNamed: "cat")
        cat.position = CGPoint(
            x:CGFloat.random(min: playableRect.minX, max: playableRect.maxX),
            y:CGFloat.random(min: playableRect.minY, max: playableRect.maxY)
        )
        cat.setScale(0) //start scale at 0
        addChild(cat)
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)//grows from nothing to max in 0.5 seconds
        let wait = SKAction.wait(forDuration: 10.0) // 10 seconds before next spawn
        let dissapear = SKAction.scale(to: 0, duration: 0.5) //reduce to zero after time limit
        let removeFromParent = SKAction.removeFromParent() //remove sprite
        let actions = [appear, wait, dissapear, removeFromParent] //set sequence
        cat.run(SKAction.sequence(actions))
    }
    
    
    
    
    
    
    
    
    
    
/*****************************************************
NOTES
 ******************************************************/

//BACKGROUND
//        background.position = CGPoint(x: size.width/2, y: size.height/2)
//        background.anchorPoint = CGPoint.zero
//        background.zRotation = CGFloat.pi / 8
    
//SPRITE
//        zombie.anchorPoint = CGPoint(x: 0.5, y: 0.5)
//        zombie1.setScale(2) // SKNode method

    
//    OLD - SPrite movement

//    func move(sprite: SKSpriteNode, velocity: CGPoint)
//    {
//        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),
//                                   y: velocity.y * CGFloat(dt))
//        print("Amount to move: \(amountToMove)")
//        sprite.position = CGPoint(
//            x: sprite.position.x + amountToMove.x,
//            y: sprite.position.y + amountToMove.y)
//    }


//// V SHAPED ENEMY MOVEMENT MOVE.BY VERSION
//    let enemy = SKSpriteNode(imageNamed: "enemy")       //Select sprite
//        enemy.position = CGPoint(x:size.width + enemy.size.width/2, y:size.height/2)  //Set starting position
//                addChild(enemy)
//
//    let actionMidMove = SKAction.moveBy(
//        x: -size.width/2-enemy.size.width/2,
//        y: -playableRect.height/2 + enemy.size.height/2,
//        duration: 1.0)
//    let actionMove = SKAction.moveBy(
//        x: -size.width/2-enemy.size.width/2,
//        y: playableRect.height/2 - enemy.size.height/2,
//        duration: 1.0)
//    let wait = SKAction.wait(forDuration: 0.5)
//    let logMessage = SKAction.run()
//        {
//            print("Reached bottom!")
//        }
//
////Reverse the sequence
//        let halfSequence = SKAction.sequence([actionMidMove, logMessage, wait, actionMove])
//        let sequence = SKAction.sequence([halfSequence, halfSequence.reversed()])
//
//        enemy.run(sequence)
//    }
        
//    //V SHAPED ENEMY MOVEMENT MOVE.TO VERSION
//    let enemy = SKSpriteNode(imageNamed: "enemy")       //Select sprite
//    
//    enemy.position = CGPoint(x:size.width + enemy.size.width/2, y:size.height/2)  //Set starting position
//    addChild(enemy)
//    // 1
//    let actionMidMove = SKAction.move(to: CGPoint(x: size.width/2, y: playableRect.minY + enemy.size.height/2),
//        duration: 1.5) //Move to bottom middle screen
//    // 2
//    let actionMove = SKAction.move(to: CGPoint(x: -enemy.size.width/1, y: enemy.position.y),duration: 1.5) //Move to far leftr middle screen
//    // 3
//    let wait = SKAction.wait(forDuration: 1) //pause enemy on bottom of the screen
//    let logMessage = SKAction.run()
//        {
//            print("Reached bottom!")
//        }
//    let sequence = SKAction.sequence([actionMidMove, logMessage, wait, actionMove])
//    // 4
//    enemy.run(sequence)
//    }

//    Anna
//    reservations@orteapalace.com
    
//    1. Here, you create a new move action, just like you did before, except this time it represents the “mid-point” of the action — the bottom middle of the playable rectangle.
//    2. This is the same move action as before, except you’ve decreased the duration to 1.0, since it will now represent moving only half the distance: from the bottom of the “V”, to the left side of the screen.
//    3. Here’s the new sequence action! As you can see, it’s incredibly simple — you use the sequence(_:) constructor and pass in an Array of actions. The sequence action will run one action after another.
//    4. You call run(_:) in the same way as before, but pass in the sequence action this time.
   
    
//STRAIGHT LINE ENEMY MOVEMENT
//        //position enemy just outside RHS of screen in vertical center
//        let enemy = SKSpriteNode(imageNamed: "enemy")
//        enemy.position = CGPoint(x:size.width + enemy.size.width/2, y:size.height/2)
//        addChild(enemy)
//
//        //move enemy right to left, action moves a node relative to its current position.
//        let actionMove = SKAction.move(to: CGPoint(x: -enemy.size.width/2, y: enemy.position.y),
//            duration: 5.0)
//        enemy.run(actionMove)
    
    
    
// ROTATE ZOMBIE
//    func rotate(sprite: SKSpriteNode, direction: CGPoint)
//    {
////  OLD
////        sprite.zRotation = CGFloat(atan2(Double(direction.y), Double(direction.x)))
//
////  NEW
//        sprite.zRotation = direction.angle
//    }
//

}





