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

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var photoImageView: UIImageView!
    
    var input: PHContentEditingInput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackgroundEffect()
    }
    
    // MARK: - PHContentEditingController

    func canHandleAdjustmentData(adjustmentData: PHAdjustmentData?) -> Bool {
        return adjustmentData?.formatIdentifier == MustacheAdjustmentData.adjustmentDataFormatIdentifier() && adjustmentData?.formatVersion == MustacheAdjustmentData.adjustmentDataformatVersion()
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
        
        backgroundImageView.image = placeholderImage
        let fullSizeImageUrl = input.fullSizeImageURL
        let fullSizeImage = UIImage(contentsOfFile: fullSizeImageUrl.path!)
        photoImageView.image = annotate(image: fullSizeImage)
    }

    func finishContentEditingWithCompletionHandler(completionHandler: ((PHContentEditingOutput!) -> Void)!) {
        dispatch_async(dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)) {
            if self.input == nil {
                completionHandler(nil)
                return
            }
            
            let output = PHContentEditingOutput(contentEditingInput: self.input)

            let adjustmentDataData = NSKeyedArchiver.archivedDataWithRootObject("mustache")
            output.adjustmentData = PHAdjustmentData(
                formatIdentifier: MustacheAdjustmentData.adjustmentDataFormatIdentifier(),
                formatVersion: MustacheAdjustmentData.adjustmentDataformatVersion(),
                data: adjustmentDataData)
            
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
        let mustacheAnnotator = MustacheAnnotator(mustacheImage: mustacheImage)
        return mustacheAnnotator.annotatedImage(sourceImage: image)
    }
    
    private func setupBackgroundEffect() {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
        effectView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.insertSubview(effectView, aboveSubview: backgroundImageView)
        
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
            "V:|[effectView]|",
            options: NSLayoutFormatOptions.allZeros,
            metrics: nil,
            views: ["effectView": effectView])
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
            "H:|[effectView]|",
            options: NSLayoutFormatOptions.allZeros,
            metrics: nil,
            views: ["effectView": effectView])
        view.addConstraints(verticalConstraints)
        view.addConstraints(horizontalConstraints)
    }

}
