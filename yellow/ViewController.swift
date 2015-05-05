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
    var selectedImage : UIImage! = nil
    var points = [Int]();
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
        points.removeAll()
        
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
        
            //points.append(touch)
        if selectedImage != nil && points.count<8{
            var location : CGPoint = touch.locationInView(imageView)
        
            var width = CGRectGetWidth(imageView.bounds)
            var height = CGRectGetHeight(imageView.bounds)
            var ratioX=width/selectedImage.size.width
            var ratioY=height/selectedImage.size.height
            var ratio=(ratioX<ratioY) ? ratioX : ratioY
            var marginX=(ratioX<ratioY) ? 0 : (width-selectedImage.size.width*ratio)/2
            var marginY=(ratioX<ratioY) ? (height-selectedImage.size.height*ratio)/2 : 0
        
            var x=(location.x-marginX)/ratio;
            var y=(location.y-marginY)/ratio;
            if (x>0 && x<selectedImage.size.width && y>0 && y<selectedImage.size.height){
                points.append(Int(x))
                points.append(Int(y))
                if(points.count==8){
                    NSLog("x0 \(points[0])")
                    imageView.image=self.imageProcessFactory.detection(self.imageView.image, pointCoords:points);
                }
            }
        }
        
    }


    
    
    
}