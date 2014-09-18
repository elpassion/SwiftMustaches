//
//  MustacheAnnotation.swift
//  SwiftMustaches
//
//  Created by Dariusz Rybicki on 18/09/14.
//  Copyright (c) 2014 EL Passion. All rights reserved.
//

import UIKit

class MustacheAnnotation {
    
    let mustacheImage: UIImage
    
    init(mustacheImage: UIImage) {
        self.mustacheImage = mustacheImage
    }
    
    func annotatedImage(#sourceImage: UIImage) -> UIImage {
        let detector = CIDetector(
            ofType: CIDetectorTypeFace,
            context: nil,
            options:
            [
                CIDetectorAccuracy: CIDetectorAccuracyHigh,
                CIDetectorTracking: false,
                CIDetectorMinFeatureSize: NSNumber(float: 0.1)
            ])
        let ciImage = CIImage(CGImage: sourceImage.CGImage)
        let features = detector.featuresInImage(
            ciImage,
            options:
            [
                CIDetectorImageOrientation: self.dynamicType.orientationFromImageOrientation(sourceImage.imageOrientation),
                CIDetectorEyeBlink: false,
                CIDetectorSmile: false
            ])
        
        UIGraphicsBeginImageContextWithOptions(sourceImage.size, true, sourceImage.scale)
        let context = UIGraphicsGetCurrentContext()!
        sourceImage.drawAtPoint(CGPointZero)
        
        for feature in features as [CIFaceFeature] {
            
            // TESTING: annotate face, eyes and mouth on image
            
            var faceRect = feature.bounds
            faceRect.origin.y = sourceImage.size.height - feature.bounds.height - feature.bounds.origin.y
            CGContextSetStrokeColorWithColor(context, UIColor.whiteColor().CGColor)
            CGContextStrokeRectWithWidth(context, faceRect, 2.0)
            
            let eyeRectSize = CGSize(width: faceRect.width / 5, height: faceRect.height / 5)
            let mouthRectSize = CGSize(width: faceRect.width / 3, height: faceRect.height / 6)
            
            if feature.hasLeftEyePosition {
                let leftEyeRect = CGRect(
                    x: feature.leftEyePosition.x - (eyeRectSize.width / 2),
                    y: sourceImage.size.height - feature.leftEyePosition.y - (eyeRectSize.height / 2),
                    width: eyeRectSize.width,
                    height: eyeRectSize.height)
                CGContextSetFillColorWithColor(context, UIColor(red: 0, green: 0, blue: 1, alpha: 0.4).CGColor)
                CGContextFillEllipseInRect(context, leftEyeRect);
            }
            
            if feature.hasRightEyePosition {
                let rightEyeRect = CGRect(
                    x: feature.rightEyePosition.x - (eyeRectSize.width / 2),
                    y: sourceImage.size.height - feature.rightEyePosition.y - (eyeRectSize.height / 2),
                    width: eyeRectSize.width,
                    height: eyeRectSize.height)
                CGContextSetFillColorWithColor(context, UIColor(red: 0, green: 0, blue: 1, alpha: 0.4).CGColor)
                CGContextFillEllipseInRect(context, rightEyeRect)
            }
            
            if feature.hasMouthPosition {
                let mouthRectSize = CGSize(
                    width: faceRect.width / 1.5,
                    height: faceRect.height / 5)
                let mouthRect = CGRect(
                    x: feature.mouthPosition.x - (mouthRectSize.width / 2),
                    y: sourceImage.size.height - feature.mouthPosition.y - (mouthRectSize.height / 2),
                    width: mouthRectSize.width,
                    height: mouthRectSize.height)
                CGContextSetFillColorWithColor(context, UIColor(red: 1, green: 0, blue: 0, alpha: 0.4).CGColor)
                CGContextFillEllipseInRect(context, mouthRect)
            }
            
            // TESTING: end
            
            if feature.hasMouthPosition {
                var faceRect = feature.bounds
                let mouthRectSize = CGSize(
                    width: faceRect.width / 1.5,
                    height: faceRect.height / 5)
                let mustacheRect = CGRect(
                    x: feature.mouthPosition.x - (mouthRectSize.width / 2),
                    y: sourceImage.size.height - feature.mouthPosition.y - mouthRectSize.height,
                    width: mouthRectSize.width,
                    height: mouthRectSize.height)
                
                let rotatedMustacheImage = self.mustacheImage.rotatedImage(CGFloat(feature.faceAngle) * CGFloat(3.14) / CGFloat(180.0))
                rotatedMustacheImage.drawInRect(mustacheRect)
            }
        }
        
        let annotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return annotatedImage
    }
    
    private class func orientationFromImageOrientation(imageOrientation: UIImageOrientation) -> Int {
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
    
}