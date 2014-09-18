//
//  ViewController.swift
//  SwiftMustaches
//
//  Created by Dariusz Rybicki on 18/09/14.
//  Copyright (c) 2014 EL Passion. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var openBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var saveBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var loading: Bool = true {
        didSet {
            self.photoImageView.hidden = loading
            self.openBarButtonItem.enabled = !loading
            self.saveBarButtonItem.enabled = !loading
            if loading {
                self.activityIndicator.startAnimating()
            }
            else {
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    var image: UIImage? {
        didSet {
            if let image = image {
                self.photoImageView.image = self.image
            }
            else {
                self.photoImageView.image = nil
            }
        }
    }

    // MARK: - UI Actions
    
    @IBAction func openBarButtonItemAction(sender: UIBarButtonItem) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
        imagePicker.delegate = self
        presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func saveBarButtonItemAction(sender: UIBarButtonItem) {
        if let image = image {
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        }
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
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if let strongSelf = self {
                            strongSelf.image = mustacheAnnotator.annotatedImage(sourceImage: image)
                            strongSelf.loading = false
                        }
                    })
                }
            })
        }
    }

}

