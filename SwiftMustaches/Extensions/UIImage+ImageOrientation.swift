//
//  UIImage+ImageOrientation.swift
//  SwiftMustaches
//
//  Created by Dariusz Rybicki on 18/09/14.
//  Copyright (c) 2014 EL Passion. All rights reserved.
//

import UIKit

extension UIImage {
    
    class func orientationPropertyValueFromImageOrientation(imageOrientation: UIImageOrientation) -> Int {
        var orientation: Int = 0
        switch imageOrientation {
        case .Up:
            orientation = 1
        case .Down:
            orientation = 3
        case .Left:
            orientation = 8
        case .Right:
            orientation = 6
        case .UpMirrored:
            orientation = 2
        case .DownMirrored:
            orientation = 4
        case .LeftMirrored:
            orientation = 5
        case .RightMirrored:
            orientation = 7
        }
        return orientation
    }
    
    func orientationPropertyValueFromImageOrientation() -> Int {
        return self.dynamicType.orientationPropertyValueFromImageOrientation(self.imageOrientation)
    }
    
}
