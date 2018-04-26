//
//  TIGStockButton.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/07/21.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

/// StockButton
class TIGStockButton: UIButton {
    
    /// TIGNotification
    let tigNotification = TIGNotification()
    
    /// initializer
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// StockButtonのfadeinout
    override func awakeFromNib() {
        tigNotification.observe(TIGNotification.fadeInOutStockButton){(payload: String) in
            if let alpha = Float(payload){
                self.alpha = CGFloat(alpha)
            }
        }
    }

}
