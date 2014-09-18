//
//  PhotoEditingViewController.swift
//  PhotoEditingExtension
//
//  Created by Dariusz Rybicki on 18/09/14.
//  Copyright (c) 2014 EL Passion. All rights reserved.
//

import UIKit
import Photos
import PhotosUI

class PhotoEditingViewController: UIViewController, PHContentEditingController {

    @IBOutlet weak var photoImageView: UIImageView!
    
    let adjustmentDataFormatIdentifier = "com.elpassion.SwiftMustaches.MustacheAnnotation"
    let adjustmentDataformatVersion = "0.1"
    
    var input: PHContentEditingInput?

    // MARK: - PHContentEditingController

    func canHandleAdjustmentData(adjustmentData: PHAdjustmentData?) -> Bool {
        return adjustmentData?.formatIdentifier == self.adjustmentDataFormatIdentifier && adjustmentData?.formatVersion == self.adjustmentDataformatVersion
    }

    func startContentEditingWithInput(contentEditingInput: PHContentEditingInput?, placeholderImage: UIImage) {
        self.input = contentEditingInput
        
        if self.input == nil {
            return
        }
        let input = self.input!
        
        if input.mediaType != .Image {
            return
        }
        
        photoImageView.image = annotate(image: input.displaySizeImage)
    }

    func finishContentEditingWithCompletionHandler(completionHandler: ((PHContentEditingOutput!) -> Void)!) {
        dispatch_async(dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)) {
            let output = PHContentEditingOutput(contentEditingInput: self.input)

            output.adjustmentData = PHAdjustmentData(formatIdentifier: self.adjustmentDataFormatIdentifier, formatVersion: self.adjustmentDataformatVersion, data: nil)
            
            let fullSizeImageUrl = self.input!.fullSizeImageURL
            let fullSizeImage = UIImage(contentsOfFile: fullSizeImageUrl.path!)
            let fullSizeAnnotatedImage = self.annotate(image: fullSizeImage)
            let fullSizeAnnotatedImageData = UIImageJPEGRepresentation(fullSizeAnnotatedImage, 0.9)
            
            var error: NSError?
            let success = fullSizeAnnotatedImageData.writeToURL(output.renderedContentURL, options: .AtomicWrite, error: &error)
            if success {
                completionHandler?(output)
            }
            else {
                NSLog("Error when writing file: \(error)")
                completionHandler?(nil)
            }
        }
    }

    var shouldShowCancelConfirmation: Bool {
        return false
    }

    func cancelContentEditing() {}
    
    // MARK: -
    
    private func annotate(#image: UIImage) -> UIImage {
        let mustacheImage = UIImage(named: "mustache")
        let mustacheAnnotation = MustacheAnnotation(mustacheImage: mustacheImage)
        return mustacheAnnotation.annotatedImage(sourceImage: image)
    }

}
