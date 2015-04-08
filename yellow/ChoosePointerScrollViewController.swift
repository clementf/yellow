//
//  ChoosePointerScrollViewController.swift
//  yellow
//
//  Created by Clement on 08/04/2015.
//  Copyright (c) 2015 isen. All rights reserved.
//

import UIKit

class ChoosePointerScrollViewController: UIScrollView {

required init(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
}



override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
    isTouched(touches)
}

func isTouched(touches: NSSet!) {
    // Get the first touch and its location in this view controller's view coordinate system
    let touch = touches.allObjects[0] as UITouch
    
    let touchLocation = touch.locationInView(self)
    var coordY = touchLocation.y / self.zoomScale;
    var coordX = touchLocation.x / self.zoomScale;
}

}
