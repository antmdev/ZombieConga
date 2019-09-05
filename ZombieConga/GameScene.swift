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
    let bonusLifeSound: SKAction = SKAction.playSoundFileNamed( //Enemy hit sound
        "439889__simonbay__lushlife-levelup.wav", waitForCompletion: false)
    var invincible = false //set the status of the zombie when not contacted by enemy
    let catMovePointsPerSec: CGFloat = 480.0    // keep track of move points per second
    var lives = 5 //adding base number of lives for Zombie
    var trainCount = 0 //setting variable for number of cats
    var gameOver = false //Game over status for Scene Change
    
    //Camera constants
    let cameraNode = SKCameraNode() //Create the camera node
    let cameraMovePointsPerSec: CGFloat = 200.0 //sets the camera scroll speed
    
    var cameraRect : CGRect //helper method that calculates the current “visible playable area”.
    {
        let x = cameraNode.position.x - size.width/2
            + (size.width - playableRect.width)/2
        let y = cameraNode.position.y - size.height/2
            + (size.height - playableRect.height)/2
        return CGRect(
            x: x,
            y: y,
            width: playableRect.width,
            height: playableRect.height)
    }
    
    //Font Constants
    // let livesLabel = SKLabelNode(fontNamed: "Chalkduster") //set font for lives
    let livesLabel = SKLabelNode(fontNamed: "Glimstick")
    let catsLabel = SKLabelNode(fontNamed: "Glimstick")
    let youWinLabel = SKLabelNode(fontNamed: "Glimstick")
    
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
        zombieAnimation = SKAction.animate(with: textures, timePerFrame: 0.1)
        
        super.init(size: size) // 5 You call the initializer of the superclass.
    }
    
    required init(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
/*****************************************************
BACKGROUND
 ******************************************************/
    
    override func didMove(to view: SKView)
    {
        backgroundColor = SKColor.black

        for i in 0...1
        {
            let background = backgroundNode()
            background.anchorPoint = CGPoint.zero
            background.position =
                CGPoint(x: CGFloat(i)*background.size.width, y: 0)
            background.name = "background"
            addChild(background)
        }
        
// SPRITE ZOMBIE
        zombie.position = CGPoint(x:400, y: 400)
        zombie.zPosition = 100 // so he stays above the cats!
        addChild(zombie)
        playBackgroundMusic(filename: "backgroundMusic.mp3")
        // SPRITE CATS SEQUENCE RUN
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
        
        // SPAWN LIVES
        run(SKAction.repeatForever(SKAction.sequence([SKAction.run()
            {
                [weak self] in self?.spawnLife()
            },
                SKAction.wait(forDuration: 10.0)])))
        
        //ADD THE CAMERA
        addChild(cameraNode) //constant camera node declared at top
        camera = cameraNode //label as camera
        cameraNode.position = CGPoint(x: size.width/2, y: size.height/2) //make it center the screen
        
        //ADDING FONTS TO SCENE LIVES
        livesLabel.text = "Lives: X"
        livesLabel.fontColor = SKColor.black
        livesLabel.fontSize = 100
        livesLabel.zPosition = 150
        livesLabel.horizontalAlignmentMode = .left // align left & Bottom
        livesLabel.verticalAlignmentMode = .bottom
        livesLabel.position = CGPoint(
            x: -playableRect.size.width/2 + CGFloat(20), //buffer off edge of screen
            y: -playableRect.size.height/2 + CGFloat(20))
        cameraNode.addChild(livesLabel)  //add as a child of the camera node to keep on screen
        
        //CATS LABEL
        catsLabel.text = "Cats: X"
        catsLabel.fontColor = SKColor.black
        catsLabel.fontSize = 100
        catsLabel.zPosition = 150
        catsLabel.horizontalAlignmentMode = .right // align right & Bottom
        catsLabel.verticalAlignmentMode = .bottom
        catsLabel.position = CGPoint(
            x: playableRect.size.width/2 - CGFloat(20),
            y: -playableRect.size.height/2 + CGFloat(20))
        cameraNode.addChild(catsLabel)  //add as a child of the camera node to keep on screen
        
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

        move(sprite: zombie, velocity: velocity)
        

        move(sprite: zombie, velocity: velocity)
        rotate(sprite: zombie, direction: velocity, rotateRadiansPerSec: zombieRotateRadiansPerSec)


        
        boundsCheckZombie() //call method to bounce off walls
        
        moveTrain()   // move cats train to follow you
        moveCamera() //call move camera method
        
        livesLabel.text = "Lives: \(lives)" //update number of lives
       
        
        if lives <= 0 && !gameOver //game over status set - if not already over & lives is <= 0
        {
            gameOver = true
            print("You lose!")
            // 1
            let gameOverScene = GameOverScene(size: size, won: false)
            gameOverScene.scaleMode = scaleMode
            // 2
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5)
            // 3
            view?.presentScene(gameOverScene, transition: reveal)
            backgroundMusicPlayer.stop()
        }
        
    }
    
/*****************************************************
SPRITE MOVEMENT
******************************************************/
    
//    NEW CODE USING MATHS LIBRARY
    func move(sprite: SKSpriteNode, velocity: CGPoint)
    {
        let amountToMove = CGPoint(x: velocity.x * CGFloat(dt),
                                   y: velocity.y * CGFloat(dt))
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
        let bottomLeft = CGPoint(x: cameraRect.minX, y: cameraRect.minY)
        let topRight = CGPoint(x: cameraRect.maxX, y: cameraRect.maxY)
        
        // Then, you check the zombie’s position to see if it’s beyond or on any of the screen edges. If it is, you clamp the position and reverse the appropriate velocity component to make the zombie bounce in the opposite direction.
        if zombie.position.x <= bottomLeft.x
        
        {//ensure that whenever the zombie reaches the left boundary, his x-velocity will stay pointed toward the right.
            zombie.position.x = bottomLeft.x
            velocity.x = abs(velocity.x)
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
            x: cameraRect.maxX + enemy.size.width/2,
            //modified the fixed y-position to be a random value between the bottom and top of the playable rectangle
            y: CGFloat.random(
                min: cameraRect.minY + enemy.size.height/2,
                max: cameraRect.maxY - enemy.size.height/2))
        enemy.zPosition = 50
        enemy.name = "enemy" // set name for enemys for collision
        addChild(enemy)
        let actionMove = SKAction.moveBy(x: -(size.width + enemy.size.width), y: 0, duration: 2.0)
      
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
        cat.name = "cat" //name cat for collisions
   //Spawn cat in visible area of the screen in screen
        cat.position = CGPoint(
            x: CGFloat.random(min: cameraRect.minX, max: cameraRect.maxX),
            y: CGFloat.random(min: cameraRect.minY, max: cameraRect.maxY))
        cat.zPosition = 50
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
SPAWN EXTRA LIFE
 ******************************************************/
    
    func spawnLife() //spawn cat  in random positions accross max playable area
    {
       let bonusLife = SKSpriteNode(imageNamed: "game-sprite-2185953_640")
        bonusLife.name = "life" //name cat for collisions
        bonusLife.position = CGPoint(
            x: CGFloat.random(min: cameraRect.minX, max: cameraRect.maxX),
            y: CGFloat.random(min: cameraRect.minY, max: cameraRect.maxY))
        bonusLife.zPosition = 50
        bonusLife.setScale(0) //start scale at 0
        
        let turnRed = SKAction.colorize(with: SKColor.red, colorBlendFactor: 1.0, duration: 0.01)
        bonusLife.run(turnRed)
        addChild(bonusLife)
        
        let appear = SKAction.scale(to: 0.45, duration: 0.5)//grows from nothing to max in 0.5 seconds
        //adding cat wiggle motion
        bonusLife.zRotation = -π / 16.0 //rotate cat 1/16 of pi ( negative rotations go clockwise)
        let leftWiggle = SKAction.rotate(byAngle: π/8.0, duration: 0.5) //rotates counterclockwise by 22.5
        let rightWiggle = leftWiggle.reversed() //reverse the above
        let fullWiggle = SKAction.sequence([leftWiggle, rightWiggle]) //combines in a sequence
        let wiggleWait = SKAction.repeat(fullWiggle, count: 10) // repeat sequence 10 times over 10 seconds

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
        bonusLife.run(SKAction.sequence(actions))
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
    
    func zombieHit(enemy: SKSpriteNode)
    {
        invincible = true
        let blinkTimes = 10.0
        let duration = 3.0
        let blinkAction = SKAction.customAction(withDuration: duration)
        {
            node, elapsedTime in
            let slice = duration / blinkTimes
            let remainder = Double(elapsedTime).truncatingRemainder(
                dividingBy: slice)
            node.isHidden = remainder > slice / 2
        }
        let setHidden = SKAction.run()
        {
            [weak self] in
            self?.zombie.isHidden = false
            self?.invincible = false
        }
        zombie.run(SKAction.sequence([blinkAction, setHidden]))
        
        run(enemyCollisionSound)
        
        loseCats() // remove two cats method
        lives -= 1 // lose a life
        
    }
    
//PICKED UP EXTRA LIFE
    
    func zombieHit(bonusLife: SKSpriteNode)
    {
        run(bonusLifeSound)
        lives += 1 // Gain a life
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
        }
        if invincible
        {
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
    

        var hitLife: [SKSpriteNode] = []
        enumerateChildNodes(withName: "life")
        {
            node, _ in
            let life = node as! SKSpriteNode
    
            if node.frame.insetBy(dx: 20, dy: 20).intersects(self.zombie.frame)
            {
                hitLife.append(life)
                node.removeFromParent()
            }
        }
        
        for life in hitLife
        {
            zombieHit(bonusLife: life)
        }
   
    } //END check collisions
        
    override func didEvaluateActions()
    { //speeds up frame rate
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
            let gameOverScene = GameOverScene(size: size, won: true)
            gameOverScene.scaleMode = scaleMode //matches  current sacle mode in gamescene
            let reveal = SKTransition.flipHorizontal(withDuration: 0.5) //transition = flip horizontal
            view?.presentScene(gameOverScene, transition: reveal) // reveal transition
            backgroundMusicPlayer.stop()
        }
         catsLabel.text = "Cats: \(trainCount)/15" //update number of Cats
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
    

/*****************************************************
COMBINE SCENES FOR SCROLLING BACKGROUND
 ******************************************************/

func backgroundNode() -> SKSpriteNode
{
    // 1 create a new SKNode to contain both background sprites as children.
    // use an SKSpriteNode with no texture
    let backgroundNode = SKSpriteNode()
    backgroundNode.anchorPoint = CGPoint.zero
    backgroundNode.name = "background"
    
    // 2 create an SKSpriteNode for the first background image and pin the bottom- left
    // of the sprite to the bottom-left of backgroundNode
    let background1 = SKSpriteNode(imageNamed: "background1")
    background1.anchorPoint = CGPoint.zero
    background1.position = CGPoint(x: 0, y: 0)
    backgroundNode.addChild(background1)
    
    // 3 create an SKSpriteNode for the second background image and pin the bottom-left
    // of the sprite to the bottom-right of background1 inside backgroundNode.
    let background2 = SKSpriteNode(imageNamed: "background2")
    background2.anchorPoint = CGPoint.zero
    background2.position = CGPoint(x: background1.size.width, y: 0)
    backgroundNode.addChild(background2)
    
    // 4 set the size of the backgroundNode based on the size of the two background images.
    backgroundNode.size = CGSize(
        width: background1.size.width + background2.size.width,
        height: background1.size.height)
    return backgroundNode
}
    // calculates the amount the camera should move this frame, and updates the
    //camera’s position accordingly.

    func moveCamera()
    {
        let backgroundVelocity = CGPoint(x: cameraMovePointsPerSec, y: 0)
        let amountToMove = backgroundVelocity * CGFloat(dt)
        cameraNode.position += amountToMove
    
        enumerateChildNodes(withName: "background")
        {
            node, _ in
            let background = node as! SKSpriteNode
            if background.position.x + background.size.width <
                self.cameraRect.origin.x
            {
                background.position = CGPoint(
                    x: background.position.x + background.size.width*2,
                    y: background.position.y)
            }
        }
    }
    
} //FINAL CLOSING BRACKET CLASS

