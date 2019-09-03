import Foundation
import SpriteKit

class MainMenuScene: SKScene
{
/*****************************************************
 INITIALISE PLAYABLE AREA
 ******************************************************/
    
    override func didMove(to view: SKView)
    {
        let background = SKSpriteNode(imageNamed: "MainMenu")
        
        background.position = CGPoint(x: size.width/2, y: size.height/2)
//        background.anchorPoint = CGPoint.zero
//        background.position = CGPoint(x: background.size.width, y: 0)
        addChild(background)
    }
    
/*****************************************************
 Function for starting game when touching
 ******************************************************/
    
    func sceneTapped()
    {
        let myScene = GameScene(size: size) // ipone
        myScene.scaleMode = scaleMode
        let reveal = SKTransition.doorway(withDuration: 1.5)
        view?.presentScene(myScene, transition: reveal)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        sceneTapped()
    }
    
}
