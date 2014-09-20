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
    var adjustment: MustacheAdjustment?
    
    var image: UIImage? {
        didSet {
            photoImageView.image = image
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupBackgroundEffect()
    }
    
    // MARK: - PHContentEditingController

    func canHandleAdjustmentData(adjustmentData: PHAdjustmentData?) -> Bool {
        return MustacheAdjustment.canHandleAdjustmentData(adjustmentData)
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
        
        if input.adjustmentData != nil {
            adjustment = MustacheAdjustment(adjustmentData: input.adjustmentData)
        }
        else {
            adjustment = MustacheAdjustment(image: fullSizeImage)
        }
        
        if adjustment!.mustachePositions.count == 0 {
            presentErrorAlertView(message: "Unable to add mustaches")
            image = fullSizeImage
        }
        else {
            image = adjustment!.applyAdjustment(fullSizeImage)
        }
    }

    func finishContentEditingWithCompletionHandler(completionHandler: ((PHContentEditingOutput!) -> Void)!) {
        dispatch_async(dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)) {
            if self.input == nil {
                completionHandler(nil)
                return
            }
            
            if self.adjustment!.mustachePositions.count == 0 {
                NSLog("Nothing changed")
                completionHandler?(nil)
                return
            }
            
            let output = PHContentEditingOutput(contentEditingInput: self.input)
            output.adjustmentData = self.adjustment!.adjustmentData()
            
            let fullSizeAnnotatedImageData = UIImageJPEGRepresentation(self.image, 0.9)
            
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
    
    private func presentErrorAlertView(#message: String) -> Void {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }

}
