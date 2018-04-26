//
//  TIGPlayerWipeButton.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/06/26.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit


/// wipeViewをタッチした際の動きを制御するボタン
class TIGPlayerWipeButton: UIButton {

    
    /// TIGPlayer
    weak var player: TIGPlayer?{
        didSet{
            if self.player?.displayMode != .Wipe {
                self.stopAnimation()
            }
        }
    }
    
    ///initializer
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
        setTitle(nil, for:.normal)
        setImage(TIGPlayerControlButton.playImage, for:.normal)
        addTarget(self,action: #selector(TIGPlayerWipeButton.respondToButton), for:.touchUpInside)
    }

    
    /// wideからwipeへ変更する際に呼ばれる
    func stopAnimation() {
        self.player?.pause()
    }

    
    /// wipeからwideへ戻る際に呼ばれる
    open func respondToButton() {
        guard let player = self.player else{
            return
        }
        player.toWide()
        if let controlView = player.controlView as? TIGPlayerWideControlView{
            if controlView.didProgressGetToEnd(slider: controlView.timeSlider){
                player.stop()
                controlView.shareButton.display(parentViewAlpha: 0.8, replayViewhidden: false)
            }else{
                player.play()
            }
            if (self.player?.state)! != .stopped {
                controlView.playerControlButton.setBackGroundToStop()
            }
            controlView.player(player, orientationDidChange: deviceInfo.orientation)
        }
    }
}
