//
//  RectUtil.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/09/26.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import Foundation

extension CGRect{
    var longerSide:CGFloat{
        get{
            return self.width > self.height ? self.width:self.height
        }
    }
}
