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
        /*var instanceOfCustomObject: ImageProcessFactory = ImageProcessFactory()
        instanceOfCustomObject.someProperty = "Hello World"
        println(instanceOfCustomObject.someProperty)
        instanceOfCustomObject.someMethod()*/
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
    
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        selectedImage = info[UIImagePickerControllerOriginalImage] as! UIImage;
        picker.dismissViewControllerAnimated(true, completion: nil);
        
        var instanceOfCustomObject: ImageProcessFactory = ImageProcessFactory()
        imageView.image = selectedImage
        self.scrollView.zoomScale = 1
        self.stopCamera();
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
                    imageView.image=self.imageProcessFactory.detection(self.imageView.image, pointCoords:points);
                    var zoomPoint:CGPoint = self.imageProcessFactory.getFirstCoordinates();
                    
                    width = CGRectGetWidth(imageView.bounds)
                    height = CGRectGetHeight(imageView.bounds)
                    ratioX=width/imageView.image!.size.width
                    ratioY=height/imageView.image!.size.height                    
                    var newRatio=(ratioX<ratioY) ? ratioX : ratioY
                    marginX=(ratioX<ratioY) ? 0 : (width-imageView.image!.size.width*ratio)/2
                    marginY=(ratioX<ratioY) ? (height-imageView.image!.size.height*ratio)/2 : 0
                    zoomPoint.x = zoomPoint.x * newRatio + marginX
                    zoomPoint.y = zoomPoint.y * newRatio + marginY
                    var rectToZoom = CGRectMake(zoomPoint.x - 40, zoomPoint.y - 40, 80, 80);
                    self.scrollView.zoomToRect(rectToZoom, animated: true)
                }
            }
        }
        
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