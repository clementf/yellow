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
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let touch = touches.first as? UITouch {
            self.superview?.touchesBegan(touches, withEvent: event)
        }
        super.touchesBegan(touches , withEvent:event)
    }

}
