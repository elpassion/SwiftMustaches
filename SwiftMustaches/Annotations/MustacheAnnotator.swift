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
                
                let rotatedMustacheImage = self.mustacheImage.rotatedImage(CGFloat(feature.faceAngle) * CGFloat(3.14) / CGFloat(180.0))
                rotatedMustacheImage.drawInRect(mustacheRect)
            }
        }
        
        let annotatedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return annotatedImage
    }
    
}