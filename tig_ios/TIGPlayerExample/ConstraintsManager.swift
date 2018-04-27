//
//  ConstraintsManager.swift
//  WebView
//
//  Created by 小林 宏知 on 2018/02/02.
//  Copyright © 2018年 小林 宏知. All rights reserved.
//

import Foundation
import UIKit

class ConstraintsManager{
    
    func create(item:Any,toItem:Any,attribute:NSLayoutAttribute,constant:CGFloat = 0) ->NSLayoutConstraint{
        return NSLayoutConstraint(
            item: item,
            attribute: attribute,
            relatedBy: NSLayoutRelation.equal,
            toItem: toItem,
            attribute: attribute,
            multiplier: 1.0,
            constant: constant
        )
    }
    
    func activate(constraints:[NSLayoutConstraint]){
        NSLayoutConstraint.activate(constraints)
    }
}

