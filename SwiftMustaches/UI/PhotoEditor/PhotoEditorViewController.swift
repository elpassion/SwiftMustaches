//
//  PhotoEditorViewController.swift
//  SwiftMustaches
//
//  Created by Dariusz Rybicki on 18/09/14.
//  Copyright (c) 2014 EL Passion. All rights reserved.
//

import UIKit
import Photos

class PhotoEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPhotoLibraryChangeObserver {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var openBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var revertBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var activityIndicatorContainerView: UIView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var input: PHContentEditingInput? {
        didSet {
            if let input = input {
                if input.adjustmentData != nil {
                    let fullSizeImageUrl = input.fullSizeImageURL
                    let fullSizeImage = UIImage(contentsOfFile: fullSizeImageUrl.path!)
                    let annotatedImage = annotate(image: fullSizeImage)
                    photoImageView.image = annotatedImage
                }
                else {
                    photoImageView.image = input.displaySizeImage
                }
            }
            else {
                photoImageView.image = nil
            }
            updateUI()
        }
    }
    
    var asset: PHAsset?
    
    private var loading: Bool = false {
        didSet {
            updateUI()
        }
    }
    
    private var saving: Bool = false {
        didSet {
            updateUI()
        }
    }
    
    // MARK: - UI
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicatorContainerView.layer.cornerRadius = 10
        updateUI()
        PHPhotoLibrary.sharedPhotoLibrary().registerChangeObserver(self)
    }
    
    private func updateUI() {
        dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
            if let strongSelf = self {
                let isLoading = strongSelf.loading
                let isSaving = strongSelf.saving
                let isInputSet = (strongSelf.input != nil)
                let isInputModified = (strongSelf.input?.adjustmentData != nil)
                strongSelf.photoImageView.hidden = isLoading || !isInputSet
                strongSelf.openBarButtonItem.enabled = !isLoading && !isSaving
                strongSelf.saveBarButtonItem.enabled = !isLoading && !isSaving && isInputSet && !isInputModified
                strongSelf.revertBarButtonItem.enabled = !isLoading && !isSaving && isInputModified
                strongSelf.activityIndicatorContainerView.hidden = !isLoading && !isSaving
                if isLoading || isSaving {
                    strongSelf.activityIndicatorView.startAnimating()
                }
                else {
                    strongSelf.activityIndicatorView.stopAnimating()
                }
            }
        })
    }
    
    private func presentErrorAlertView(#message: String) -> Void {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // MARK: - UI Actions
    
    @IBAction func openBarButtonItemAction(sender: UIBarButtonItem) {
        openPhoto()
    }
    
    @IBAction func saveBarButtonItemAction(sender: UIBarButtonItem) {
        savePhoto()
    }
    
    @IBAction func revertBarButtonItemAction(sender: UIBarButtonItem) {
        revertModifications()
    }
    
    // MARK: - Opening photo
    
    private func openPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
        imagePicker.delegate = self
        loading = true
        presentViewController(imagePicker, animated: true, completion: nil)
    }

    private func loadAsset(asset: PHAsset?, completion: (() -> Void)?) {
        if asset == nil {
            self.asset = nil
            self.input = nil

            if let completion = completion {
                completion()
            }
            
            return
        }
        let asset = asset!
        
        let options = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = { (adjustmentData) -> Bool in
            return adjustmentData.formatIdentifier == MustacheAdjustmentData.adjustmentDataFormatIdentifier() && adjustmentData.formatVersion == MustacheAdjustmentData.adjustmentDataformatVersion()
        }
        
        asset.requestContentEditingInputWithOptions(options, completionHandler: { [weak self] (input, info) -> Void in
            if self == nil {
                NSLog("Error: aborting due to VC deallocation")
                return
            }
            
            if input.adjustmentData == nil {
                NSLog("Loaded asset WITHOUT adjustment data")
            }
            else {
                NSLog("Loaded asset WITH adjustment data")
            }
            
            self!.asset = asset
            self!.input = input
            
            if let completion = completion {
                completion()
            }
        })
    }
    
    // MARK: - Saving photo
    
    private func savePhoto() {
        if self.input == nil {
            presentErrorAlertView(message: "Can't save, no input")
            return
        }
        let input = self.input!
        
        if self.asset == nil {
            presentErrorAlertView(message: "Can't save, no asset")
            return
        }
        let asset = self.asset!
        
        saving = true
        
        let output = PHContentEditingOutput(contentEditingInput: input)
        output.adjustmentData = MustacheAdjustmentData.adjustmentData()
        
        let fullSizeImageUrl = input.fullSizeImageURL
        let fullSizeImage = UIImage(contentsOfFile: fullSizeImageUrl.path!)
        let fullSizeAnnotatedImage = annotate(image: fullSizeImage)
        let fullSizeAnnotatedImageData = UIImageJPEGRepresentation(fullSizeAnnotatedImage, 0.9)
        
        var error: NSError?
        let success = fullSizeAnnotatedImageData.writeToURL(output.renderedContentURL, options: .AtomicWrite, error: &error)
        if !success {
            presentErrorAlertView(message: "Error when writing file: \(error?.localizedDescription)")
            saving = false
            return
        }
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ [weak self] () -> Void in
            if self == nil {
                NSLog("Error: aborting due to VC deallocation")
                return
            }
            
            if self!.asset == nil {
                self!.presentErrorAlertView(message: "Can't perform modifications, no asset")
                self!.saving = false
                return
            }
            let asset = self!.asset
            
            let request = PHAssetChangeRequest(forAsset: asset)
            request.contentEditingOutput = output
            
        }, completionHandler: { [weak self] (success, error) -> Void in
            if !success {
                self?.presentErrorAlertView(message: "Error saving modifications: \(error?.localizedDescription)")
                self?.saving = false
                return
            }
            
            NSLog("Photo modifications performed successfully")
            self?.saving = false
        })
    }
    
    // MARK: - Reverting modifications
    
    private func revertModifications() {
        if self.input == nil {
            presentErrorAlertView(message: "Can't revert, no input")
            return
        }
        let input = self.input!
        
        if self.asset == nil {
            presentErrorAlertView(message: "Can't revert, no asset")
            return
        }
        let asset = self.asset!
        
        saving = true
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ [weak self] () -> Void in
            if self == nil {
                NSLog("Error: aborting due to VC deallocation")
                return
            }
            
            if self!.asset == nil {
                self!.presentErrorAlertView(message: "Can't perform revert, no asset")
                self!.saving = false
                return
            }
            let asset = self!.asset
            
            let request = PHAssetChangeRequest(forAsset: asset)
            request.revertAssetContentToOriginal()
            
        }, completionHandler: { [weak self] (success, error) -> Void in
            if !success {
                self?.presentErrorAlertView(message: "Error reverting modifications: \(error?.localizedDescription)")
                self?.saving = false
                return
            }
            
            NSLog("Photo modifications reverted successfully")
            self?.saving = false
        })
    }
    
    // MARK: - Helper methods
    
    private func annotate(#image: UIImage) -> UIImage {
        let mustacheImage = UIImage(named: "mustache")
        let mustacheAnnotator = MustacheAnnotator(mustacheImage: mustacheImage)
        return mustacheAnnotator.annotatedImage(sourceImage: image)
    }

    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]!)  {
        let assetUrlOptional: NSURL? = info[UIImagePickerControllerReferenceURL] as? NSURL
        if assetUrlOptional == nil {
            NSLog("Error: no asset URL")
            loading = false
            return
        }
        let assetUrl = assetUrlOptional!
        
        let fetchResult = PHAsset.fetchAssetsWithALAssetURLs([ assetUrl ], options: nil)
        if fetchResult.firstObject == nil {
            NSLog("Error: asset not fetched")
            loading = false
            return
        }
        let asset = fetchResult.firstObject! as PHAsset
        
        if !asset.canPerformEditOperation(PHAssetEditOperation.Content) {
            NSLog("Error: asset can't be edited")
            loading = false
            return
        }
        
        dismissViewControllerAnimated(true, completion: nil)
        
        loadAsset(asset, completion: { [weak self] () -> Void in
            self?.loading = false
            return
        })
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
        loading = false
    }
    
    // MARK: - PHPhotoLibraryChangeObserver
    
    func photoLibraryDidChange(changeInstance: PHChange!) {
        dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
            if self?.asset == nil {
                return
            }
            
            let changeDetailsForAsset = changeInstance.changeDetailsForObject(self!.asset!)
            if changeDetailsForAsset == nil {
                return
            }
            
            if changeDetailsForAsset.objectWasDeleted {
                NSLog("PhotoLibrary: Asset deleted")
                self?.loading = true
                self?.loadAsset(nil, completion: { () -> Void in
                    self?.loading = false
                    return
                })
                return
            }
            
            if changeDetailsForAsset.assetContentChanged {
                if let assetAfterChanges = changeDetailsForAsset.objectAfterChanges as? PHAsset {
                    NSLog("PhotoLibrary: Asset changed")
                    self?.loading = true
                    self?.loadAsset(assetAfterChanges, completion: { () -> Void in
                        self?.loading = false
                        return
                    })
                }
            }
        })
    }
    
}
