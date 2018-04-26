//
//  TIGPlayerControlBar.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/05/30.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

/// フッターメニュー
class TIGPlayerControlBar: UIView {
    /// TIGPlayerWideControlViewインスタンス
    weak var controlView :TIGPlayerWideControlView?
    
    /// TIGPlayer
    weak var player: TIGPlayer?{
        didSet{
            self.controlView = self.player?.controlView as? TIGPlayerWideControlView
            NSLog("controlView: \(String(describing: self.controlView?.description))")
        }
    }

    
    /// TIGNotification
    let tigNotification = TIGNotification()
    
    /// 表示タイマー
    var timer:Timer? = Timer()
        
    /// 高さ
    let height:(portrait:CGFloat,landscape:CGFloat) = (100,50)
    
    ///initializer
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear
        self.layer.insertSublayer(TIGGradientColor.paintColor(paintFrame:bounds, top: false), at: 1)

        tigNotification.observe(TIGNotification.toggleBar) { _ in
            self.toggleBarAnination()
        }
        tigNotification.observe(TIGNotification.showBar) { _ in
            self.show()
        }
        self.adjustSizeInCurrentOrientation()
    }

    ///deinitializer
    deinit{
        self.timer?.invalidate()
        self.timer = nil
    }

    /// 表示、非表示切り替え
    func toggleBarAnination() {
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
        }, completion:{(bool:Bool) -> Void in
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer( timeInterval: 2, target: self, selector: #selector(self.hide), userInfo: nil, repeats: false )
        })
    }

    /// 非表示
    func hide(){
        UIView.animate(withDuration: 0.16, delay: 0, options: .curveEaseIn, animations: {
            self.layer.opacity = 0
        }, completion:nil)
    }

    /// 表示されているかどうか
    ///
    /// - Returns: layer.opacity == 1
    func isShown() -> Bool{
        return self.layer.opacity == 1
    }
    
    /// 現在の端末方向に合わせてサイズ調整
    func adjustSizeInCurrentOrientation(){
        let largestCordinates = deviceInfo.largestCordinates
        if deviceInfo.isLandScape{
            self.frame.size.height = height.landscape
            self.frame.origin.y = largestCordinates.maxY - height.landscape
        }else{
            self.frame.size.height = height.portrait
            self.frame.origin.y = largestCordinates.maxY - height.portrait
        }
    }
}
