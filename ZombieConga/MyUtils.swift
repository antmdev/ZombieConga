//
//  MyUtils.swift
//  ZombieConga
//
//  Created by Ant Milner on 26/08/2019.
//  Copyright © 2019 Ant Milner. All rights reserved.
//

import Foundation
import CoreGraphics



//MATHEMATICAL VECTOR BASED HELP ROUTINES

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
func += (left: inout CGPoint, right: CGPoint) {
    left = left + right
}


func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}
func -= (left: inout CGPoint, right: CGPoint) {
    left = left - right
}
func * (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x * right.x, y: left.y * right.y)
}
func *= (left: inout CGPoint, right: CGPoint) {
    left = left * right
}
func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x * scalar, y: point.y * scalar)
}
func *= (point: inout CGPoint, scalar: CGFloat) {
    point = point * scalar
}
func / (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x / right.x, y: left.y / right.y)
}
func /= ( left: inout CGPoint, right: CGPoint) {
    left = left / right
}
func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
    return CGPoint(x: point.x / scalar, y: point.y / scalar)
}
func /= (point: inout CGPoint, scalar: CGFloat) {
    point = point / scalar
}


#if !(arch(x86_64) || arch(arm64))
func atan2(y: CGFloat, x: CGFloat) -> CGFloat {
    return CGFloat(atan2f(Float(y), Float(x)))
}
func sqrt(a: CGFloat) -> CGFloat {
    return CGFloat(sqrtf(Float(a)))
}
#endif

//the class extension adds some handy methods to get the length of the point, return a normalized version of the point (i.e., length 1) and get the angle of the point.

extension CGPoint {
    func length() -> CGFloat {
        return sqrt(x*x + y*y)
    }
    func normalized() -> CGPoint {
        return self / length()
    }
    var angle: CGFloat {
        return atan2(y, x)
    }
}

//HELPER  ROUTINES TO SMOOTH OUT ROTATION
//Basically works out whether its quicker to turn left or right based on the shortest angle.

let π = CGFloat.pi
func shortestAngleBetween(angle1: CGFloat, angle2: CGFloat) -> CGFloat // returns the shortest angle between two angles.
{
    let twoπ = π * 2.0
    var angle = (angle2 - angle1)
        .truncatingRemainder(dividingBy: twoπ)
    if angle >= π {
        angle = angle - twoπ
    }
    if angle <= -π {
        angle = angle + twoπ
    }
    return angle
}
extension CGFloat {
    func sign() -> CGFloat // Sign() returns 1 if the CGFloat is greater than or equal to 0; otherwise it returns -1.
    {
        return self >= 0.0 ? 1.0 : -1.0
    }
}
