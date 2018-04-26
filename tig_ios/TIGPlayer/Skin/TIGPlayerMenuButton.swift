//
//  TIGPlayerMenuButton.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/06/20.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit


/// メニューボタン
/// @ACCESS_OPEN
open class TIGPlayerMenuButton: UIButton {
    /// TIGNotification
    let tigNotification = TIGNotification()
    
    /// 表示タイマー
    var timer:Timer? = Timer()
    
    /// TIGPlayerWideControlViewインスタンス
    weak var wideControlView :TIGPlayerWideControlView?
    
    /// TIGPlayer
    weak var player: TIGPlayer?{
        didSet{
            self.wideControlView = self.player?.controlView as? TIGPlayerWideControlView
        }
    }

    /// initializer
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        backgroundColor = UIColor.clear
        self.addTarget(self,action: #selector(TIGPlayerMenuButton.respondToButton), for:.touchUpInside)
        
        tigNotification.observe(TIGNotification.toggleBar) { _ in
            self.toggleBtnAnima()
        }
        tigNotification.observe(TIGNotification.showBar) { _ in
            self.show()
        }
    }

    /// 表示、非表示切り替え
    func toggleBtnAnima() {
        if isShown(){
            self.hide()
        }else{
            self.show()
        }
    }
    
    /// 表示
    func show(){
        UIView.animate(withDuration: 0.16, delay: 0, options: .curveEaseIn, animations: {
            self.layer.opacity = 1
            self.wideControlView?.creatTopGradient()
        }, completion:{(bool:Bool) -> Void in
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer( timeInterval: 2, target: self, selector: #selector(self.hide), userInfo: nil, repeats: false )
        })
    }
    
    /// 非表示
    func hide(){
        UIView.animate(withDuration: 0.16, delay: 0, options: .curveEaseIn, animations: {
            self.layer.opacity = 0
            self.wideControlView?.gradientLayer.removeFromSuperlayer()
        }, completion:nil)
    }
    
    /// 表示されているかどうか
    ///
    /// - Returns: layer.opacity == 1
    func isShown() -> Bool{
        return self.layer.opacity == 1
    }
    
    /// playerを解放してコンテンツリストに戻る
    open func respondToButton() {
        guard let player = self.player else {
            return
        }
        player.stopAndRelease()
    }
}
