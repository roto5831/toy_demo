//
//  TIGPlayerTimeLabel.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/06/20.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

/// 再生時間表示ラベル
class TIGPlayerTimeLabel: UILabel {
    
    ///initializer
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        backgroundColor = UIColor.clear
    }
}
