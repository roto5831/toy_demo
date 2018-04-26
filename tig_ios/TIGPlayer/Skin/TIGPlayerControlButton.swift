//
//  TIGPlayerControllButton.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/05/30.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

protocol TIGPlayerControlButtonComplement:class{
    func didReplay()
}

/// 再生、一時停止ボタン
/// @ACCESS_OPEN
open class TIGPlayerControlButton: UIButton{
    
    /// TIGNotification
    let tigNotification = TIGNotification()
    
    /// TIGPlayer
    weak var player: TIGPlayer?
    
    weak var comp:TIGPlayerControlButtonComplement?
    
    ///initializer
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.backgroundColor = UIColor.clear
        self.imageView?.contentMode = .scaleAspectFit

        self.setBackGroundToStop()
        self.addTarget(self,action: #selector(TIGPlayerControlButton.respondToButton), for:.touchUpInside)

        tigNotification.observe(TIGNotification.replay) { _ in
            self.replay()
        }
    }

    /// 背景画像を一時停止にする
    open func setBackGroundToStop(){
        setImage(TIGPlayerControlButton.stopImage, for:.normal)
    }

    /// 背景画像を再生にする
    open func setBackGroundToPlay(){
        setImage(TIGPlayerControlButton.playImage, for:.normal)
    }

    /// 背景画像をリプレイにする
    open func setBackGroundToReplay(){
        setImage(TIGPlayerControlButton.replayImage, for:.normal)
    }

    /// リプレイ
    private func replay(){
        self.setBackGroundToStop()
        self.player?.seek(to: 0.0)
        self.player?.play()
        self.comp?.didReplay()
    }
    
    /// 再生、一時停止を切り替える
    open func respondToButton() {

        guard let player = self.player else {
            return
        }
        switch player.state {
        case .playing:
            TIGLog.debug(message:"Player State Playing", anyObject: player.state)
            self.setBackGroundToPlay()
            player.pause()
            break
        case .pause:
            TIGLog.debug(message:"Player State Pause", anyObject: player.state)
            self.setBackGroundToStop()
            player.play()
            break
        case .stopped, .readyToPlay:
            TIGLog.debug(message:"Player State Stopped", anyObject: player.state)
            self.replay()
            break
        case .buffering:
            TIGLog.debug(message:"Player State Buffering", anyObject: player.state)
            break
        case .bufferFinished:
            TIGLog.debug(message:"Player State BufferFinished", anyObject: player.state)
            break
        default:
            break
        }
    }
}
