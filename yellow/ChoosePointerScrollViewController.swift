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
        self.superview?.touchesBegan(touches, withEvent: event)
        super.touchesBegan(touches , withEvent:event)
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.superview?.touchesEnded(touches, withEvent: event)
        super.touchesEnded(touches , withEvent:event)
    }
}
