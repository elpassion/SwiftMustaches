//
//  MustacheAdjustmentData.swift
//  SwiftMustaches
//
//  Created by Konrad Szczesniak on 19/09/14.
//  Copyright (c) 2014 EL Passion. All rights reserved.
//

import Foundation
import Photos

class MustacheAdjustmentData {
    
    class func adjustmentDataFormatIdentifier() -> String {
        return "com.elpassion.SwiftMustaches.MustacheAnnotator";
    }
    
    class func adjustmentDataformatVersion() -> String {
        return "0.1"
    }
    
    class func adjustmentData() -> PHAdjustmentData {
        let adjustmentData = PHAdjustmentData(
            formatIdentifier: MustacheAdjustmentData.adjustmentDataFormatIdentifier(),
            formatVersion: MustacheAdjustmentData.adjustmentDataformatVersion(),
            data: NSKeyedArchiver.archivedDataWithRootObject("mustache"))
        
        return adjustmentData
    }
}
