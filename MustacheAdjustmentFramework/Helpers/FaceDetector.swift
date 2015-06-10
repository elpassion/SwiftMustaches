//
//  FaceDetector.swift
//  SwiftMustaches
//
//  Created by Dariusz Rybicki on 21/09/14.
//  Copyright (c) 2014 EL Passion. All rights reserved.
//

import UIKit
import CoreImage

class FaceDetector {
    
    class func detectFaces(inImage image: UIImage) -> [CIFaceFeature] {
        let detector = CIDetector(
            ofType: CIDetectorTypeFace,
            context: nil,
            options: [
                CIDetectorAccuracy: CIDetectorAccuracyHigh,
                CIDetectorTracking: false,
                CIDetectorMinFeatureSize: NSNumber(float: 0.1)
            ])
        
        UIGraphicsBeginImageContextWithOptions(image.size, true, image.scale)
        _ = UIGraphicsGetCurrentContext()
        image.drawAtPoint(CGPointZero)
        let cgImage = UIGraphicsGetImageFromCurrentImageContext().CGImage!
        let ciImage = CIImage(CGImage: cgImage)
        UIGraphicsEndImageContext()
        
        let features = detector.featuresInImage(
            ciImage,
            options: [
                CIDetectorImageOrientation: UIImage.orientationPropertyValueFromImageOrientation(.Up),
                CIDetectorEyeBlink: false,
                CIDetectorSmile: false
            ])
        
        NSLog("Detected faces count: \(features.count)")
        
        return features as! [CIFaceFeature]
    }
    
}