//
//  StockItemCell.swift
//  TIGPlayerExample
//
//  Created by 藤原 章敬 on 2017/05/22.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//


import UIKit

/// ストックアイテムのセル
class StockItemCell: UICollectionViewCell {

    /// 選択したかどうかの丸画像
    @IBOutlet weak var deleteBtn: UIButton!
    
    /// アイテム画像
    @IBOutlet weak var itemImage: UIImageView!

    /// 一定間隔で再描画用タイマー
    var timer: Timer!
    
    /// 回転値
    var rotate: Double = 0
    
    /// 回転速度
    var accRotate: Double = 40
    
    /// 状態 (-1: 通常, 0: 削除モード, 1,2: 削除モード終了
    var state: Int = -1
    
    /// アニメーション開始の遅延時間
    var delayTime: Double = 0
    
    /// 削除モード時の経過時間
    var time: Double = 0
    
    /// 削除モード
    open var deleteMode = false{
        didSet{
            if oldValue != deleteMode {
                if deleteMode {
                    state = 0
                    time = 0
                    delayTime = Double(arc4random_uniform(UINT32_MAX)) / Double(UINT32_MAX) * 0.2
                } else {
                    state = accRotate > 0 ? 1 : 2
                }
            }
        }
    }
    
    static let kShakeRadians: Double = 3.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupTimer()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupTimer()
    }
    
    func setupTimer() {
        timer = Timer.scheduledTimer(timeInterval: 1.0 / 60, target: self, selector: #selector(self.update), userInfo: nil, repeats: true)
        timer.fire()
    }
    
    func applyRotate() {
        let tr = CGAffineTransform.identity.rotated(by: CGFloat(rotate * Double.pi / 180.0))
        itemImage.transform = tr
        itemImage.layoutIfNeeded()
    }
    
    func update(tm: Timer) {
        if itemImage != nil {
            if state == 0 {
                time += tm.timeInterval
                
                if time >= delayTime {
                    rotate += accRotate / 60.0
                    if ((rotate >= StockItemCell.kShakeRadians) || (rotate <= -StockItemCell.kShakeRadians)) {
                        accRotate = -accRotate;
                    }
                    
                    applyRotate()
                }
            } else if state == 1 {
                rotate -= accRotate
                if rotate <= 0 {
                    rotate = 0
                    state = -1
                }
                
                applyRotate()
            } else if state == 2 {
                rotate -= accRotate
                if rotate >= 0 {
                    rotate = 0
                    state = -1
                }
                
                applyRotate()
            }
        }
    }
}
