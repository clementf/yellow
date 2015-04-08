//
//  ViewController.swift
//  yellow
//  CVOpenStitch
//  Created by Clement on 21/01/2015.
//  Copyright (c) 2015 isen. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate, UIScrollViewDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    var selectedImage : UIImage!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Custom initialization
    }
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        /*var instanceOfCustomObject: ImageProcessFactory = ImageProcessFactory()
        instanceOfCustomObject.someProperty = "Hello World"
        println(instanceOfCustomObject.someProperty)
        instanceOfCustomObject.someMethod()*/
        super.viewDidLoad()
        self.scrollView.delegate = self;
        self.scrollView.maximumZoomScale = 100.0;
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)    }
    
    func viewForZoomingInScrollView(scrollView:UIScrollView) -> UIView {
        return self.imageView!
    }
    
    @IBAction func onTakePictureTapped(sender: AnyObject) {
        var imagePicker = UIImagePickerController()
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: NSDictionary!) {
        selectedImage = image;
        picker.dismissViewControllerAnimated(true, completion: nil);
        
        var instanceOfCustomObject: ImageProcessFactory = ImageProcessFactory()
        imageView.image = image
        
        imageView.frame = CGRectMake(0, imageView.frame.origin.y, image.size.width, image.size.height);
        var ratioW = self.scrollView.frame.width / image.size.width
        var ratioH = self.scrollView.frame.height / image.size.height
        var ratio = ratioH
        
        if(ratioH > ratioW){
            ratio = ratioW
        }
        self.scrollView.contentSize = image.size
        self.scrollView.minimumZoomScale = ratio
        self.scrollView.zoomScale = ratio
        
        
    }
    
    
    
}