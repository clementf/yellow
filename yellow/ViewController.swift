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
    var points = Array<Int>();
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
        self.scrollView.zoomScale = 1
        
        
    }



    override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        isTouched(touches)
    }

    func isTouched(touches: NSSet!) {
        // Get the first touch and its location in this view controller's view coordinate system
        let touch = touches.allObjects[0] as UITouch
        let touchLocation = touch.locationInView(self.scrollView)
        points.append(Int(Float(touchLocation.y) / Float(self.scrollView.zoomScale)));
        points.append(Int(Float(touchLocation.x) / Float(self.scrollView.zoomScale)));
        
        if(points.count == 8){
            self.imageProcessFactory.transformPerspective(self.imageView.image, zoomScale:1, pointCoords:points);
        }
        
    }


    
    
    
}