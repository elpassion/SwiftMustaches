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
        
        UIGraphicsBeginImageContext(sourceImage.size)
        let context = UIGraphicsGetCurrentContext()!
        sourceImage.drawAtPoint(CGPointZero)
        
        for feature in features as [CIFaceFeature] {
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
                
                let rotatedMustacheImage = self.rotatedImage(self.mustacheImage, angle: CGFloat(feature.faceAngle) * CGFloat(3.14) / CGFloat(180.0))
                rotatedMustacheImage.drawInRect(mustacheRect)
            }
        }
        
        let annotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return annotatedImage
    }
    
    private func rotatedImage(image: UIImage, angle: CGFloat) -> UIImage {
        let rotatedViewBox = UIView(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let rotatedViewBoxTransform = CGAffineTransformMakeRotation(angle)
        rotatedViewBox.transform = rotatedViewBoxTransform
        let rotatedSize = rotatedViewBox.frame.size
        
        UIGraphicsBeginImageContext(rotatedSize)
        let context = UIGraphicsGetCurrentContext()!
        CGContextTranslateCTM(context, rotatedSize.width / 2, rotatedSize.height / 2);
        CGContextRotateCTM(context, angle)
        image.drawInRect(CGRect(
            x: -image.size.width / 2,
            y: -image.size.height / 2,
            width: image.size.width,
            height: image.size.height))
        
        let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return rotatedImage
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