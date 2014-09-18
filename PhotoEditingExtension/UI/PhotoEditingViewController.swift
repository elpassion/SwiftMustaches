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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - PHContentEditingController

    func canHandleAdjustmentData(adjustmentData: PHAdjustmentData?) -> Bool {
        // Inspect the adjustmentData to determine whether your extension can work with past edits.
        // (Typically, you use its formatIdentifier and formatVersion properties to do this.)
        return false
    }

    func startContentEditingWithInput(contentEditingInput: PHContentEditingInput?, placeholderImage: UIImage) {
        // Present content for editing, and keep the contentEditingInput for use when closing the edit session.
        // If you returned YES from canHandleAdjustmentData:, contentEditingInput has the original image and adjustment data.
        // If you returned NO, the contentEditingInput has past edits "baked in".
        self.input = contentEditingInput
        
        if self.input == nil {
            return
        }
        let input = self.input!
        
        if input.mediaType != .Image {
            return
        }
        
        let mustacheImage = UIImage(named: "mustache")
        let mustacheAnnotation = MustacheAnnotation(mustacheImage: mustacheImage)
        
        let displaySizeImage = input.displaySizeImage
        let displaySizeAnnotatedImage = mustacheAnnotation.annotatedImage(sourceImage: displaySizeImage)
        
        photoImageView.image = displaySizeAnnotatedImage
    }

    func finishContentEditingWithCompletionHandler(completionHandler: ((PHContentEditingOutput!) -> Void)!) {
        // Update UI to reflect that editing has finished and output is being rendered.
        
        // Render and provide output on a background queue.
        dispatch_async(dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)) {
            // Create editing output from the editing input.
            let output = PHContentEditingOutput(contentEditingInput: self.input)
            
            // Provide new adjustments and render output to given location.
            // output.adjustmentData = <#new adjustment data#>
            // let renderedJPEGData = <#output JPEG#>
            // renderedJPEGData.writeToURL(output.renderedContentURL, atomically: true)
            
            output.adjustmentData = PHAdjustmentData(formatIdentifier: self.adjustmentDataFormatIdentifier, formatVersion: self.adjustmentDataformatVersion, data: nil)
            
            let mustacheImage = UIImage(named: "mustache")
            let mustacheAnnotation = MustacheAnnotation(mustacheImage: mustacheImage)
            
            let fullSizeImageUrl = self.input!.fullSizeImageURL
            let fullSizeImage = UIImage(contentsOfFile: fullSizeImageUrl.path!)
            let fullSizeAnnotatedImage = mustacheAnnotation.annotatedImage(sourceImage: fullSizeImage)
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
            
            // Clean up temporary files, etc.
        }
    }

    var shouldShowCancelConfirmation: Bool {
        // Determines whether a confirmation to discard changes should be shown to the user on cancel.
        // (Typically, this should be "true" if there are any unsaved changes.)
        return false
    }

    func cancelContentEditing() {
        // Clean up temporary files, etc.
        // May be called after finishContentEditingWithCompletionHandler: while you prepare output.
    }

}
