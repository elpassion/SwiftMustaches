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
    
    var image: UIImage? {
        didSet {
            if let image = image {
                self.photoImageView.image = image
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
            self.image = image
            dismissViewControllerAnimated(true, completion: nil)
        }
    }

}

