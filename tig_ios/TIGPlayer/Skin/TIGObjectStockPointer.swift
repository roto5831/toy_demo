//
//  TIGPlayerStockPointer.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/07/03.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import Foundation
import UIKit

/// Stockした際に描画される矢印
class TIGObjectStockPointer:UIImageView{

    /// TIGNotification
    let tigNotifi = TIGNotification()
    
    /// initializer
    ///
    /// - Parameter frame: frame
    override init(frame:CGRect){
        super.init(frame:frame)
        self.initialize(thumbframe: frame)
    }
    
    /// initializer
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// 初期化時にアニメーションの通知設定等
    func initialize(thumbframe:CGRect){
        self.image = UIImage(named:"arrow",in: Bundle(for:TIGObjectStockPointer.self), compatibleWith: nil)
        self.alpha = 1.0
        self.isHidden = true
        self.frame = CGRect.init(x: thumbframe.origin.x + thumbframe.width,
                                 y: thumbframe.origin.y + (thumbframe.height/2 - self.frame.height/2),
                                 width: TIGObjectStockPointer.arrowFrame.width,
                                 height: TIGObjectStockPointer.arrowFrame.height)
        
        // 2018.2.16
//        // 矢印表示アニメーション
//        self.tigNotifi.observe(TIGNotification.dispArrow) {_ in
//            // alpha値を1.0から0.0まで繰り返し変化させる
//            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.repeat], animations: {
//                self.isHidden = false
//                self.alpha = 0.0
//            }, completion: { finished in
//            })
//        }
//
//        // 矢印隠すアニメーション
//        self.tigNotifi.observe(TIGNotification.hideArrow) {_ in
//            // alpha値を1.0に戻して、隠す
//            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.repeat], animations: {
//                self.alpha = 1.0
//                self.isHidden = true
//            }, completion: { finished in
//            })
//        }
    }
    
    /// サムネイルの位置により矢印の位置調整
    ///
    /// - Parameter frame:
    func adjustCordinates(itemFrame:CGRect){
        self.frame.origin = CGPoint(x: itemFrame.origin.x + itemFrame.size.width, y: itemFrame.origin.y + (itemFrame.height/2 - self.frame.height/2))
    }
}
