//
//  TIGStockListCell.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/04/24.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import SDWebImage

/// StockList内のセル
class TIGStockListCell: UITableViewCell {

    /// item imageを内包したview
    var itemImageView: UIImageView!
    
    /// 一定間隔で再描画用タイマー
    var timer: Timer!
    
    /// 半径
    var radius: Double = 0
    
    /// 半径のアニメーション速度
    var accRadius: Double = 80

    /// アニメーションの経過時間
    var time: Double = 0
    
    /// 状態
    var state: Int = 0
    
    /// 追加アニメーションモード
    open var addAnimationMode = false{
        didSet{
            if addAnimationMode {
                radius = Double(self.itemImageView.frame.height / 2)
                time = 0
                state = 1
                
                itemImageView.layer.cornerRadius = CGFloat(radius)
                itemImageView.layoutIfNeeded()
                
            }
        }
    }
    
    /// initializer
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder: ) has not been implemented")
    }
    
    
    /// initializer
    ///
    /// - Parameters:
    ///   - style: UITableViewCellStyle
    ///   - reuseIdentifier: reuseIdentifier
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.isUserInteractionEnabled = true
        self.itemImageView = UIImageView.init(frame: CGRect.init(x: 4,
                                                                 y: 4,
                                                                 width: TIGStockListCell.size,
                                                                 height: TIGStockListCell.size))
        self.itemImageView.backgroundColor = UIColor.clear
        self.itemImageView.clipsToBounds = true
        self.itemImageView.isUserInteractionEnabled = true
        self.contentView.addSubview(itemImageView)
        setupTimer()
    }
    
    func setupTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0 / 60, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    func update(tm: Timer) {
        if itemImageView != nil {
            if state == 1 {
                time += tm.timeInterval
                if time >= 0.1 {
                    var rate = (time - 0.1) / 1.2
                    rate = min(1, rate)
                    
                    // easeOutQuad
                    rate = -(rate * (rate - 2))
                    rate = 1 - rate
                    itemImageView.layer.cornerRadius = CGFloat(radius * rate)
                    itemImageView.layoutIfNeeded()
                    
                    if rate == 0{
                        state = 0
                    }
                }
            }
        }
    }
    
    /// urlからイメージをロードしてセット
    ///
    /// - Parameter urlString: urlString
    func setImageWeb(urlString: String) {
        itemImageView.sd_setImage(with: NSURL(string:urlString)! as URL )
    }
}
