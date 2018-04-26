//
//  TIGPlayerLayerView.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2016/01/16.
//  Copyright © 2016年 MMizogaki. All rights reserved.
//

import UIKit
import AVFoundation

/// 動画が出力されるView
/// TIGPlayerとその制御を担当するcontrolViewのwrapper
/// TIGPlayerView
///     player
///     controlView
///         wide
///             TIGPlayerWideControlView
///         wipe
///             TIGPlayerWipeView
class TIGPlayerView: UIView,UIGestureRecognizerDelegate {
    
    /// TIGPlayer
    weak open var player: TIGPlayer?
    
    /// controlView
    weak var controlView: UIView?{
        didSet{
            if oldValue != controlView{
                oldValue?.removeFromSuperview()
                self.addSubview(controlView!)
                self.setNeedsDisplay()
                if let customAction =  controlView as? TIGPlayerCustomAction{
                    customAction.player = player
                }
            }
        }
    }

    /// AVPlayerLayerを返すように上書き
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    // initializer
    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        self.commonInit()

    }


    /// initializer
    ///
    /// - Parameter controlView: controlView
    init(controlView: UIView? ) {
        if let controlView = controlView{
            super.init(frame: controlView.frame)
        }else{
            super.init(frame: CGRect.zero)
        }
        self.controlView = controlView
        self.commonInit()
    }

    /// initializer
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    /// layoutSubviewsを上書きしてsubviewの設定
    override func layoutSubviews() {
        super.layoutSubviews()
        self.bounds = deviceInfo.bounds
        self.controlView?.frame = self.bounds
        print("device bounds when laying out subviews \(deviceInfo.bounds.size)")
        if let playerLayer = self.layer as? AVPlayerLayer{
            print("video rect \(playerLayer.videoRect.size)")
            print("video grabity \(playerLayer.videoGravity)")
            print("video presentation video size \(self.player!.getPresentationVideoSize())")
        }
        
        
    }

    // 動画を出力できるように設定
    func config(player: TIGPlayer){
        (self.layer as! AVPlayerLayer).player = player.player
        if let customAction =  self.controlView as? TIGPlayerCustomAction{
            customAction.player = player
        }
        self.player = player
    }
    
    /// superviewのサイズが変更された際にリサイズするためにautoresizingMask適用
    private func commonInit() {
        self.backgroundColor = UIColor.black
        self.clipsToBounds = true
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth,.flexibleLeftMargin,.flexibleTopMargin,.flexibleRightMargin,.flexibleBottomMargin]
        self.controlView?.autoresizingMask = [.flexibleLeftMargin,.flexibleTopMargin,.flexibleRightMargin,.flexibleBottomMargin]
        self.addSubview(self.controlView!)

    }
}
