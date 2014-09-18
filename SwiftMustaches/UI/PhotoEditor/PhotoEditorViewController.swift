//
//  PhotoEditorViewController.swift
//  SwiftMustaches
//
//  Created by Dariusz Rybicki on 18/09/14.
//  Copyright (c) 2014 EL Passion. All rights reserved.
//

import UIKit

class PhotoEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var openBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    private var image: UIImage? {
        didSet {
            updateUI()
            self.photoImageView.image = image
        }
    }
    
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
    
    private func updateUI() {
        self.photoImageView.hidden = loading
        self.openBarButtonItem.enabled = !loading && !saving
        self.saveBarButtonItem.enabled = !loading && !saving && (self.photoImageView.image != nil)
        if loading || saving {
            self.activityIndicatorView.startAnimating()
        }
        else {
            self.activityIndicatorView.stopAnimating()
        }
    }
    
    // MARK: - UI Actions
    
    @IBAction func openBarButtonItemAction(sender: UIBarButtonItem) {
        openPhoto()
    }
    
    @IBAction func saveBarButtonItemAction(sender: UIBarButtonItem) {
        savePhoto()
    }
    
    // MARK: - Opening photo
    
    private func openPhoto() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
        imagePicker.delegate = self
        loading = true
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - Saving photo
    
    private func savePhoto() {
        if let image = image {
            saving = true
            UIImageWriteToSavedPhotosAlbum(image, self, Selector("image:didFinishSavingWithError:contextInfo:"), nil)
        }
    }
    
    func image(image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafePointer<()>) {
        dispatch_async(dispatch_get_main_queue(), { [weak self] () -> Void in
            self?.saving = false

            if let error: NSError = error {
                NSLog("Error when saving photo: \(error)")
                return
            }
            
            NSLog("Photo saved!")
        })
    }

    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]!)  {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            dismissViewControllerAnimated(true, completion: nil)
            loading = true
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { [weak self] () -> Void in
                let mustacheImage: UIImage? = UIImage(named: "mustache")
                if let mustacheImage = mustacheImage {
                    let mustacheAnnotator = MustacheAnnotator(mustacheImage: mustacheImage)
                    let mustachedImage = mustacheAnnotator.annotatedImage(sourceImage: image)
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if let strongSelf = self {
                            strongSelf.image = mustachedImage
                            strongSelf.loading = false
                        }
                    })
                }
            })
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        loading = false
    }
    
}
