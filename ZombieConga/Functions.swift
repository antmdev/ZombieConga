//
//  Functions.swift
//  ZombieConga
//
//  Created by Ant Milner on 05/09/2019.
//  Copyright © 2019 Ant Milner. All rights reserved.
//

import Foundation
import SpriteKit

func wiggleAnnimation()
{
    let appear = SKAction.scale(to: 1.0, duration: 0.5)//grows from nothing to max in 0.5 seconds
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

}
