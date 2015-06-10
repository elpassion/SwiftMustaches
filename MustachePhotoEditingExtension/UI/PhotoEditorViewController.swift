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
import MustacheAdjustmentFramework

class PhotoEditorViewController: UIViewController, PHContentEditingController {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var photoImageView: UIImageView!
    
    var input: PHContentEditingInput?
    var adjustment: MustacheAdjustment?
    var adjustmentAlreadySet: Bool = false
    
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
        backgroundImageView.image = placeholderImage
        
        if self.input == nil {
            return
        }
        let input = self.input!
        
        if input.mediaType != .Image {
            presentErrorAlertView(message: "Mustaches can only be added to images")
            return
        }
        
        let fullSizeImageUrl = input.fullSizeImageURL!
        let fullSizeImage = UIImage(contentsOfFile: fullSizeImageUrl.path!)
        
        adjustment = MustacheAdjustment(adjustmentData: input.adjustmentData)
        adjustmentAlreadySet = (adjustment != nil)
        
        if adjustmentAlreadySet == false {
            NSLog("Loaded asset WITHOUT adjustment data")
            adjustment = MustacheAdjustment(image: fullSizeImage!)
        }
        else {
            NSLog("Loaded asset WITH adjustment data")
        }
        
        if let adjustment = adjustment {
            image = adjustment.applyAdjustment(fullSizeImage!)
        }
        else {
            presentErrorAlertView(message: "Unable to add mustaches")
            image = fullSizeImage
        }
    }

    func finishContentEditingWithCompletionHandler(completionHandler: ((PHContentEditingOutput!) -> Void)!) {
        dispatch_async(dispatch_get_global_queue(CLong(DISPATCH_QUEUE_PRIORITY_DEFAULT), 0)) {
            let isInputSet = (self.input != nil)
            let isAdjustmentSet = (self.adjustment != nil)
            let isMustachePositionSet = (self.adjustment?.mustachePositions.count > 0)
            let wasAdjustmentAlreadySet = self.adjustmentAlreadySet
            
            let output = PHContentEditingOutput(contentEditingInput: self.input!)

            if !isInputSet || !isAdjustmentSet || !isMustachePositionSet || wasAdjustmentAlreadySet {
                NSLog("Nothing changed")
                completionHandler?(output)
                return
            }
            
            output.adjustmentData = self.adjustment!.adjustmentData()
            
            let fullSizeAnnotatedImageData = UIImageJPEGRepresentation(self.image!, 0.9)!
            
            do {
                try fullSizeAnnotatedImageData.writeToURL(output.renderedContentURL, options: .AtomicWrite)
                NSLog("Saved successfully")
                completionHandler?(output)
            }
            catch let error as NSError {
                NSLog("Error when writing file: \(error)")
                completionHandler?(nil)
            }
            catch {
                fatalError()
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
        effectView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(effectView, aboveSubview: backgroundImageView)
        
        let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
            "V:|[effectView]|",
            options: NSLayoutFormatOptions(),
            metrics: nil,
            views: ["effectView": effectView])
        let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat(
            "H:|[effectView]|",
            options: NSLayoutFormatOptions(),
            metrics: nil,
            views: ["effectView": effectView])
        view.addConstraints(verticalConstraints)
        view.addConstraints(horizontalConstraints)
    }
    
    private func presentErrorAlertView(message message: String) -> Void {
        dispatch_async(dispatch_get_main_queue()) { [weak self] () -> Void in
            let alertController = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self?.presentViewController(alertController, animated: true, completion: nil)
        }
    }

}
