//
//  ViewController.swift
//  yellow
//  CVOpenStitch
//  Created by Clement on 21/01/2015.
//  Copyright (c) 2015 isen. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate, UIScrollViewDelegate,UIActionSheetDelegate, AVCaptureVideoDataOutputSampleBufferDelegate{
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var previewView: UIView!
    var blurEffectView: UIVisualEffectView!
    var selectedImage : UIImage! = nil
    var points = [Int]();
    var imageProcessFactory = ImageProcessFactory();

    
    //Camera Capture requiered properties
    var videoDataOutput: AVCaptureVideoDataOutput!;
    var videoDataOutputQueue : dispatch_queue_t!;
    var previewLayer:AVCaptureVideoPreviewLayer!;
    var captureDevice : AVCaptureDevice!
    let session=AVCaptureSession();
    var currentFrame:CIImage!
    var done = false;
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        // Custom initialization
    }
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.delegate = self;
        self.scrollView.minimumZoomScale = 1
        self.scrollView.maximumZoomScale = 100.0;
        
        // Camera view setup
        var screenSize = UIScreen.mainScreen().bounds.size;
        self.previewView = UIView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height));
        self.previewView.contentMode = UIViewContentMode.ScaleAspectFit
        self.view.addSubview(previewView);
        self.setupAVCapture();
        
        if !UIAccessibilityIsReduceTransparencyEnabled() {
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.Light)
            self.blurEffectView = UIVisualEffectView(effect: blurEffect)
            self.blurEffectView.frame = view.bounds //view is self.view in a UIViewController
            previewView.addSubview(blurEffectView)
            
            //add auto layout constraints so that the blur fills the screen upon rotating device
            self.blurEffectView.setTranslatesAutoresizingMaskIntoConstraints(false)
            view.addConstraint(NSLayoutConstraint(item: blurEffectView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Top, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: blurEffectView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Bottom, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: blurEffectView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Leading, multiplier: 1, constant: 0))
            view.addConstraint(NSLayoutConstraint(item: blurEffectView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: view, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0))
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if !done {
            session.startRunning();
        }
    }
    
    
    override func shouldAutorotate() -> Bool {
        if (UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeLeft ||
            UIDevice.currentDevice().orientation == UIDeviceOrientation.LandscapeRight ||
            UIDevice.currentDevice().orientation == UIDeviceOrientation.Unknown) {
                return false;
        }
        else {
            return true;
        }
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
        let actionSheet = UIActionSheet(title: "Choisir une photo", delegate: self, cancelButtonTitle: "Annuler", destructiveButtonTitle: nil, otherButtonTitles: "Prendre une photo", "Choisir dans la librairie")
        
        actionSheet.showInView(self.view)
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int)
    {
        if(buttonIndex>0){
            var imagePicker = UIImagePickerController()
            imagePicker.sourceType = (buttonIndex>1 ? UIImagePickerControllerSourceType.PhotoLibrary : UIImagePickerControllerSourceType.Camera)
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.presentViewController(imagePicker, animated: true, completion: nil)
        }
    }
    
    func typePositionsOnImage(inImage: UIImage, points:Array<AnyObject>)->UIImage{
        
        var textColor: UIColor=UIColor(red: 0, green: 0.53, blue: 0.8, alpha: 1)
        var textFont: UIFont = UIFont(name: "Helvetica Bold", size: 40)!
        
        UIGraphicsBeginImageContext(inImage.size)
        
        //Setups up the font attributes that will be later used to dictate how the text should be drawn
        let textFontAttributes = [
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: textColor,
        ]
        
        //Put the image into a rectangle as large as the original image.
        inImage.drawInRect(CGRectMake(0, 0, inImage.size.width, inImage.size.height))
        
        for i in 1...points.count{
            var point:CGPoint=points[i-1].CGPointValue()
            var rect: CGRect = CGRectMake(point.x, point.y, inImage.size.width, inImage.size.height)
            var drawText:NSString=NSString(format:"%d", i)
            drawText.drawInRect(rect, withAttributes: textFontAttributes)
        }
        
        var newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
        
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        self.stopCamera()
        self.scrollView.zoomScale = 1
        activityIndicator.startAnimating()
        selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage;
        imageView.image = nil
        picker.dismissViewControllerAnimated(true, completion: nil);
        let qualityOfServiceClass = QOS_CLASS_BACKGROUND
        let backgroundQueue = dispatch_get_global_queue(qualityOfServiceClass, 0)
        dispatch_async(backgroundQueue, {
            self.imageProcessFactory = ImageProcessFactory()
            
            self.selectedImage=self.imageProcessFactory.detection(self.selectedImage);
            if(self.selectedImage != nil){
                self.points.removeAll()
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.activityIndicator.stopAnimating()
                    
                    
                    var pointsCoordinates:Array=self.imageProcessFactory.getAllCoordinates()
                    self.selectedImage=self.typePositionsOnImage(self.selectedImage, points: pointsCoordinates)
                    self.imageView.image = self.selectedImage
                    
                    //Zoom first ball
                    var zoomPoint:CGPoint = pointsCoordinates[0].CGPointValue()
                    var width = CGRectGetWidth(self.imageView.bounds)
                    var height = CGRectGetHeight(self.imageView.bounds)
                    var ratioX=width/self.imageView.image!.size.width
                    var ratioY=height/self.imageView.image!.size.height
                    var ratio=(ratioX<ratioY) ? ratioX : ratioY
                    var marginX=(ratioX<ratioY) ? 0 : (width-self.imageView.image!.size.width*ratio)/2
                    var marginY=(ratioX<ratioY) ? (height-self.imageView.image!.size.height*ratio)/2 : 0
                    zoomPoint.x = zoomPoint.x * ratio + marginX
                    zoomPoint.y = zoomPoint.y * ratio + marginY
                    var rectToZoom = CGRectMake(zoomPoint.x - 40, zoomPoint.y - 40, 80, 80);
                    self.scrollView.zoomToRect(rectToZoom, animated: true)
                    
                    
                })
            }
            else{
                var alert = UIAlertController(title: "Erreur", message: self.imageProcessFactory.getError(), preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.activityIndicator.stopAnimating()
                })
            }
            
        })
    }
}
// AVCaptureVideoDataOutputSampleBufferDelegate protocol and related methods
extension ViewController:  AVCaptureVideoDataOutputSampleBufferDelegate{
    func setupAVCapture(){
        session.sessionPreset = AVCaptureSessionPreset640x480;
        
        let devices = AVCaptureDevice.devices();
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice;
                    if captureDevice != nil {
                        beginSession();
                        done = true;
                        break;
                    }
                }
            }
        }
    }
    
    func beginSession(){
        var err : NSError? = nil
        var deviceInput:AVCaptureDeviceInput = AVCaptureDeviceInput(device: captureDevice, error: &err);
        if err != nil {
            println("error: \(err?.localizedDescription)");
        }
        if self.session.canAddInput(deviceInput){
            self.session.addInput(deviceInput);
        }
        
        self.videoDataOutput = AVCaptureVideoDataOutput();
        var rgbOutputSettings = [NSNumber(integer: kCMPixelFormat_32BGRA):kCVPixelBufferPixelFormatTypeKey];
        self.videoDataOutput.alwaysDiscardsLateVideoFrames=true;
        self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
        self.videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue);
        if session.canAddOutput(self.videoDataOutput){
            session.addOutput(self.videoDataOutput);
        }
        self.videoDataOutput.connectionWithMediaType(AVMediaTypeVideo).enabled = true;
        
        self.previewLayer = AVCaptureVideoPreviewLayer(session: self.session);
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        var rootLayer :CALayer = self.previewView.layer;
        rootLayer.masksToBounds=true;
        self.previewLayer.frame = rootLayer.bounds;
        rootLayer.addSublayer(self.previewLayer);
        session.startRunning();
        
    }
    
    func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
        currentFrame =   self.convertImageFromCMSampleBufferRef(sampleBuffer);
    }
    
    // clean up AVCapture
    func stopCamera(){
        self.previewView.removeFromSuperview()

        session.stopRunning()
        done = false;
    }
    
    func convertImageFromCMSampleBufferRef(sampleBuffer:CMSampleBuffer) -> CIImage{
        let pixelBuffer:CVPixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
        var ciImage:CIImage = CIImage(CVPixelBuffer: pixelBuffer)
        return ciImage;
    }
}