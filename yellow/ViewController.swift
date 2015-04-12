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
    var points = [Float]();
    var imageProcessFactory = ImageProcessFactory();

    
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
        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 100.0;
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)    }
    
    func viewForZoomingInScrollView(scrollView:UIScrollView) -> UIView? {
        return self.imageView!
    }
    
    @IBAction func onTakePictureTapped(sender: AnyObject) {
        var imagePicker = UIImagePickerController()
        imagePicker.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        self.presentViewController(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage;
        picker.dismissViewControllerAnimated(true, completion: nil);
        
        var instanceOfCustomObject: ImageProcessFactory = ImageProcessFactory()
        imageView.image = selectedImage
        self.scrollView.zoomScale = 1
        
        
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let touch = touches.first as? UITouch {
            if touch.tapCount==2{
                NSObject.cancelPreviousPerformRequestsWithTarget(self)
            }
        }
    }

    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let touch = touches.first as? UITouch{
            if (touch.tapCount == 2) {
                isTouched(touch)
            }
        }
    }

    func isTouched(touch: UITouch) {
        // Get the first touch and its location in this view controller's view coordinate system
        //points.append(Int(Float(touchLocation.y) / Float(self.scrollView.zoomScale)));
        //points.append(Int(Float(touchLocation.x) / Float(self.scrollView.zoomScale)));
        
            //points.append(touch)
        var location : CGPoint = touch.locationInView(imageView)
        points.append(Float(location.x));
        points.append(Float(location.y));
        var width = CGRectGetWidth(imageView.bounds)
        var height = CGRectGetHeight(imageView.bounds)
        if(points.count==8){
            //self.imageProcessFactory.transformPerspective(self.imageView.image, pointCoords:points);
        }
    }


    
    
    
}