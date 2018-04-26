//
//  DictonaryUtil.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/10/04.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import Foundation

extension Dictionary{
    var paramQuery:String{
        get{
            var param = "?"
            guard self.count != 0 else{
                return param
            }
            self.forEach{key,val in
                param = "\(param)\(key)=\(val)&"
            }
            
            return param.substring(to: param.index(before: param.endIndex))
        }
    }
}

