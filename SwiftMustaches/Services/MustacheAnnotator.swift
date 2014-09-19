//
//  MustacheAnnotator.swift
//  SwiftMustaches
//
//  Created by Dariusz Rybicki on 18/09/14.
//  Copyright (c) 2014 EL Passion. All rights reserved.
//

import UIKit

class MustacheAnnotator {
    
    let mustacheImage: UIImage
    
    struct MustachePosition {
        let rect: CGRect
        let angle: CGFloat
    }
    
    init(mustacheImage: UIImage) {
        self.mustacheImage = mustacheImage
    }
    
    func annotatedImage(#sourceImage: UIImage, error: NSErrorPointer?) -> UIImage {
        let detector = CIDetector(
            ofType: CIDetectorTypeFace,
            context: nil,
            options:
            [
                CIDetectorAccuracy: CIDetectorAccuracyHigh,
                CIDetectorTracking: false,
                CIDetectorMinFeatureSize: NSNumber(float: 0.1)
            ])
        
        UIGraphicsBeginImageContextWithOptions(sourceImage.size, true, sourceImage.scale)
        let context = UIGraphicsGetCurrentContext()!
        sourceImage.drawAtPoint(CGPointZero)
        
        let ciImage = CIImage(CGImage: UIGraphicsGetImageFromCurrentImageContext()!.CGImage)
        let features = detector.featuresInImage(
            ciImage,
            options:
            [
                CIDetectorImageOrientation: UIImage.orientationPropertyValueFromImageOrientation(.Up),
                CIDetectorEyeBlink: false,
                CIDetectorSmile: false
            ])
        
        var mustacheAdded = false
        
        for faceFeature in features as [CIFaceFeature] {
            if let mustachePosition = self.dynamicType.mustachePosition(imageSize: sourceImage.size, faceFeature: faceFeature) {
                let mustacheImage = self.mustacheImage.rotatedImage(mustachePosition.angle)
                mustacheImage.drawInRect(mustachePosition.rect)
                mustacheAdded = true
                NSLog("Mustache added")
            }
            else {
                NSLog("Mustache position not found")
            }
        }
        
        if !mustacheAdded {
            error?.memory = NSError(domain: "", code: 0, userInfo: nil)
        }
        
        let annotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return annotatedImage
    }
    
    class func mustachePosition(#imageSize: CGSize, faceFeature: CIFaceFeature) -> MustachePosition? {
        if !faceFeature.hasMouthPosition { return nil }
        
        let mustacheSize = CGSize(
            width: faceFeature.bounds.width / 1.5,
            height: faceFeature.bounds.height / 5)
        
        let mustacheRect = CGRect(
            x: faceFeature.mouthPosition.x - (mustacheSize.width / 2),
            y: imageSize.height - faceFeature.mouthPosition.y - mustacheSize.height,
            width: mustacheSize.width,
            height: mustacheSize.height)
        
        var mustacheAngle: CGFloat
        if faceFeature.hasFaceAngle {
            mustacheAngle = CGFloat(faceFeature.faceAngle) * CGFloat(3.14) / CGFloat(180.0)
        }
        else {
            mustacheAngle = CGFloat(0)
            NSLog("Mustache angle not found, using \(mustacheAngle)")
        }
        
        return MustachePosition(rect: mustacheRect, angle: mustacheAngle)
    }
    
}






