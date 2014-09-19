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
    
    let adjustmentDataFormatIdentifier = "com.elpassion.SwiftMustaches.MustacheAnnotator"
    let adjustmentDataformatVersion = "0.1"
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var openBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var revertBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var input: PHContentEditingInput? {
        didSet {
            if let input = input {
                photoImageView.image = annotate(image: input.displaySizeImage)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
                if isLoading || isSaving {
                    strongSelf.activityIndicatorView.startAnimating()
                }
                else {
                    strongSelf.activityIndicatorView.stopAnimating()
                }
            }
        })
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
            return adjustmentData.formatIdentifier == self.adjustmentDataFormatIdentifier && adjustmentData.formatVersion == self.adjustmentDataformatVersion
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
            NSLog("Error: can't save, no input")
            return
        }
        let input = self.input!
        
        if self.asset == nil {
            NSLog("Error: can't save, no asset")
            return
        }
        let asset = self.asset!
        
        saving = true
        
        let output = PHContentEditingOutput(contentEditingInput: input)
        
        let adjustmentDataData = NSKeyedArchiver.archivedDataWithRootObject("mustache")
        output.adjustmentData = PHAdjustmentData(
            formatIdentifier: adjustmentDataFormatIdentifier,
            formatVersion: adjustmentDataformatVersion,
            data: adjustmentDataData)
        
        let fullSizeImageUrl = input.fullSizeImageURL
        let fullSizeImage = UIImage(contentsOfFile: fullSizeImageUrl.path!)
        let fullSizeAnnotatedImage = annotate(image: fullSizeImage)
        let fullSizeAnnotatedImageData = UIImageJPEGRepresentation(fullSizeAnnotatedImage, 0.9)
        
        var error: NSError?
        let success = fullSizeAnnotatedImageData.writeToURL(output.renderedContentURL, options: .AtomicWrite, error: &error)
        if !success {
            NSLog("Error when writing file: \(error)")
            saving = false
            return
        }
        
        PHPhotoLibrary.sharedPhotoLibrary().performChanges({ [weak self] () -> Void in
            if self == nil {
                NSLog("Error: aborting due to VC deallocation")
                return
            }
            
            if self!.asset == nil {
                NSLog("Error: can't perform modifications, no asset")
                self!.saving = false
                return
            }
            let asset = self!.asset
            
            let request = PHAssetChangeRequest(forAsset: asset)
            request.contentEditingOutput = output
            
        }, completionHandler: { [weak self] (success, error) -> Void in
            if !success {
                NSLog("Error saving modifications: \(error)")
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
            NSLog("Error: can't revert, no input")
            return
        }
        let input = self.input!
        
        if self.asset == nil {
            NSLog("Error: can't revert, no asset")
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
                NSLog("Error: can't perform revert, no asset")
                self!.saving = false
                return
            }
            let asset = self!.asset
            
            let request = PHAssetChangeRequest(forAsset: asset)
            request.revertAssetContentToOriginal()
            
        }, completionHandler: { [weak self] (success, error) -> Void in
            if !success {
                NSLog("Error reverting modifications: \(error)")
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
