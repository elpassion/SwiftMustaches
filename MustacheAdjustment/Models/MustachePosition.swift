//
//  MustachePosition.swift
//  SwiftMustaches
//
//  Created by Dariusz Rybicki on 20/09/14.
//  Copyright (c) 2014 EL Passion. All rights reserved.
//

import UIKit

public class MustachePosition: NSObject {
    
    public let rect: CGRect
    public let angle: CGFloat
    
    public init(rect: CGRect, angle: CGFloat) {
        self.rect = rect
        self.angle = angle
    }
    
    public required init(coder aDecoder: NSCoder) {
        self.rect = aDecoder.decodeCGRectForKey("rect")
        self.angle = aDecoder.decodeObjectForKey("angle") as CGFloat
    }
    
    public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeCGRect(rect, forKey: "rect")
        aCoder.encodeObject(angle, forKey: "angle")
    }
    
}