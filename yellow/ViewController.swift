//
//  ViewController.swift
//  yellow
//  CVOpenStitch
//  Created by Clement on 21/01/2015.
//  Copyright (c) 2015 isen. All rights reserved.
//

import UIKit

class SwViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet var spinner:UIActivityIndicatorView!
    @IBOutlet var imageView:UIImageView?
    @IBOutlet var scrollView:UIScrollView!
    
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
    
}