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
    let catCollisionSound: SKAction = SKAction.playSoundFileNamed( //Cat hit sound
        "hitCat.wav", waitForCompletion: false)
    let enemyCollisionSound: SKAction = SKAction.playSoundFileNamed( //Enemy hit sound
        "hitCatLady.wav", waitForCompletion: false)
    var invincible = false //set the status of the zombie when not contacted by enemy
    let catMovePointsPerSec: CGFloat = 480.0    // keep track of move points per second
    var lives = 5 //adding base number of lives for Zombie
    var gameOver = false //Game over status for Scene Change
    
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
        zombie.zPosition = 100 // so he stays above the cats!
        
        addChild(zombie)
        
//        zombie.run(SKAction.repeatForever(zombieAnimation)) //Runs the animation for the zombie
    

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
        
        moveTrain()   // move cats train to follow you
        
        if lives <= 0 && !gameOver //game over status set - if not already over & lives is <= 0
        {
            gameOver = true
            print("You lose!")
        }
        
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
 SPAWN ENEMY CAT LADY
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
        
        enemy.name = "enemy" // set name for enemys for collision
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
        cat.name = "cat" //name cat for collisions
        
        cat.position = CGPoint(
            x:CGFloat.random(min: playableRect.minX, max: playableRect.maxX),
            y:CGFloat.random(min: playableRect.minY, max: playableRect.maxY)
        )
        cat.setScale(0) //start scale at 0
        addChild(cat)
        
        let appear = SKAction.scale(to: 1.0, duration: 0.5)//grows from nothing to max in 0.5 seconds
       //adding cat wiggle motion
        cat.zRotation = -π / 16.0 //rotate cat 1/16 of pi ( negative rotations go clockwise)
        let leftWiggle = SKAction.rotate(byAngle: π/8.0, duration: 0.5) //rotates counterclockwise by 22.5
        let rightWiggle = leftWiggle.reversed() //reverse the above
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle]) //combines in a sequence
//        let wiggleWait = SKAction.repeat(fullWiggle, count: 10) // repeat sequence 10 times over 10 seconds
        
        //GROUP ACTION FOR COMBINING SEQUENCES
        let scaleUp = SKAction.scale(by: 1.2, duration: 0.25)
        let scaleDown = scaleUp.reversed()
        let fullScale = SKAction.sequence(
            [scaleUp, scaleDown, scaleUp, scaleDown])
        let group = SKAction.group([fullScale, fullWiggle])
        let groupWait = SKAction.repeat(group, count: 10)
        
        //remove cat
        let disappear = SKAction.scale(to: 0, duration: 0.5) //reduce size to zero after time limit
        let removeFromParent = SKAction.removeFromParent() //remove sprite
        let actions = [appear, groupWait, disappear, removeFromParent] //set sequence
        cat.run(SKAction.sequence(actions))
    }
    
/*****************************************************
 COLLISION DETECTION
 ******************************************************/
        
    func zombieHit(cat:SKSpriteNode)
    {
//let train = SKSpriteNode(imageNamed: "cat")
        cat.name = "train"
        cat.removeAllActions()
        cat.setScale(1.0)
        cat.zRotation = 0
        
        let turnGreen = SKAction.colorize(with: SKColor.green, colorBlendFactor: 1.0, duration: 0.2)
        cat.run(turnGreen)
       
        run(catCollisionSound)
        
    }
    
    func zombieHit(enemy: SKSpriteNode) {
        invincible = true
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customAction(withDuration: duration) { node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime).truncatingRemainder(
                dividingBy: slice)
            node.isHidden = remainder > slice / 2
        }
        let setHidden = SKAction.run() { [weak self] in
            self?.zombie.isHidden = false
            self?.invincible = false
        }
        zombie.run(SKAction.sequence([blinkAction, setHidden]))
        
        run(enemyCollisionSound)
        
        loseCats() // remove two cats method
        lives -= 1 // lose a life
    }
    
    func checkCollisions()
    {
        var hitCats: [SKSpriteNode] = [] //set empty array for any sprite named cat
        enumerateChildNodes(withName: "cat")
        {
            node, _ in
            let cat = node as! SKSpriteNode
            
            if cat.frame.intersects(self.zombie.frame) //check if the frame of the cat or enemy intersects with the frame of the zombie.
            {
                hitCats.append(cat) //If there is an intersection, add the name cat or enemy to an array to keep track of it.
            }
        }
        
        for cat in hitCats
        {
            zombieHit(cat: cat)
            
            //SOUND EFFECT CAT
//            run(SKAction.playSoundFileNamed("hitCat.wav", waitForCompletion: false))
           //can now call the constant property and will stop delay of sound on first call.
        }
        
        if invincible {
            return
        }
        
        
        var hitEnemies: [SKSpriteNode] = []
        enumerateChildNodes(withName: "enemy")
        {
            node, _ in
            let enemy = node as! SKSpriteNode
            
            if node.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame) //shrink bounding box slightly as collision area is square over entire ping file including white space
            {
                hitEnemies.append(enemy)
            }
        }
        for enemy in hitEnemies
        {
            zombieHit(enemy: enemy)
            
        }
    }
        
        override func didEvaluateActions() { //speeds up frame rate
            checkCollisions()
        }
    
    
    func moveTrain()
    {
        var trainCount = 0 // set a train count of zero cats
        var targetPosition = zombie.position //create variable based on zombie position
        
        enumerateChildNodes(withName: "train")  // enumerate all children with the word train
            
        {
            node, stop in
            trainCount += 1
            if !node.hasActions()  //if the node doesn't have actions (i.e all have been removed from cat)
            {
                let actionDuration = 0.3
                let offset = targetPosition - node.position     //offset is difference between zombie and cat
                let direction = offset.normalized()             //normalise the offset into a unit vector
                let amountToMovePerSec = direction * self.catMovePointsPerSec       //velocity = the direction times cat MPS
                let amountToMove = amountToMovePerSec * CGFloat(actionDuration)     //distance = speed x time
                let moveAction = SKAction.moveBy(x: amountToMove.x, y: amountToMove.y, duration: actionDuration) //sequence
                node.run(moveAction)
            }
            targetPosition = node.position
        }
        
        if trainCount >= 15 && !gameOver
        {
            gameOver = true
            print("You win!")
        }
        
    }// MOVETRAIN()
    


/*****************************************************
LOSE CATS WHEN HIT
 ******************************************************/
        
func loseCats() {
    // 1
    var loseCount = 0
    enumerateChildNodes(withName: "train") //enumerate through the conga line
    {
        node, stop in
        
        // 2  find a random offset from the cat’s current position
        var randomSpot = node.position
        randomSpot.x += CGFloat.random(min: -100, max: 100)
        randomSpot.y += CGFloat.random(min: -100, max: 100)
      
        // 3 run a little animation to make the cat move toward the random spot, spinning around and scaling to 0 along the way. Finally, the animation removes the cat from the scene.
        node.name = ""
        node.run(
            SKAction.sequence([
                SKAction.group([
                    SKAction.rotate(byAngle: π*4, duration: 1.0),
                    SKAction.move(to: randomSpot, duration: 1.0),
                    SKAction.scale(to: 0, duration: 1.0)
                    ]),
                SKAction.removeFromParent()
                ]))
        
        // 4 update the variable that’s tracking the number of cats you’ve removed from the conga line
        loseCount += 1
        if loseCount >= 2 {
            stop[0] = true
        }
    }
    
}
    
    
    
    
    
    
    
    
} //FINAL CLOSING BRACKET CLASS

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

//BLINK ACTION DEMO

//As an example, here's an explanation of the blink action demo in ActionsCatalog:
//
//1) Divide the duration by the number of blinks desired in that time period. Call that a "slice" of time. In each slice, the node should be visible for half the time, and invisible for the other half. That is what will make the node appear to blink.
//
//2) The truncatingRemainder method returns the remainder of the first parameter (elapsedTime) after being divided by the second parameter (slice). So in this example, it gives you the amount of time that has elapsed in this "slice" calculated earlier.
//
//3) The hidden property on a node controls whether it is rendered or not. If the remainder calculated above is in the second half of the slice, it should be hidden (invisible). Otherwise it will be visible. Hence, the blink effect!
//
//Note that you can also accomplish a blink effect with a combination of hide() and unhide() actions, as you see in HideScene.
//
//*/





