//
//  MustachePosition.swift
//  SwiftMustaches
//
//  Created by Dariusz Rybicki on 20/09/14.
//  Copyright (c) 2014 EL Passion. All rights reserved.
//

import UIKit

class MustachePosition: NSObject {
    
    let rect: CGRect
    let angle: CGFloat
    
    init(rect: CGRect, angle: CGFloat) {
        self.rect = rect
        self.angle = angle
    }
    
    required init(coder aDecoder: NSCoder) {
        self.rect = aDecoder.decodeCGRectForKey("rect")
        self.angle = aDecoder.decodeObjectForKey("angle") as CGFloat
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeCGRect(rect, forKey: "rect")
        aCoder.encodeObject(angle, forKey: "angle")
    }
    
}