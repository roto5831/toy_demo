//
//  TurorialPageController.swift
//  TIGPlayerExample
//
//  Created by Michio Kobayashi on 2017/11/22.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class TutorialFirstPageViewController: UIViewController {
    /// 再生用のアイテム
    var videoURL: NSURL?
    
    /// AVPlayerItem
    var playerItem : AVPlayerItem!
    
    /// AVQueuePlayer
    var player : AVQueuePlayer!
    
    var playerLooper: NSObject?
    
    /// AVPlayerLayer
    var playerLayer : AVPlayerLayer?
    
    @IBOutlet weak var playerLayerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 端末の向きがかわったらNotificationを呼ばす設定.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.onOrientationChange(notification:)),
                                               name: NSNotification.Name.UIDeviceOrientationDidChange,
                                               object: nil)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.play(notification:)),
                                               name: NSNotification.Name.playTutorial,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.layoutIfNeeded()
        let path = Bundle.main.path(forResource: "Tutorial01", ofType: "mp4")
        let fileURL = NSURL.fileURL(withPath: path!) as NSURL
        let avAsset = AVAsset(url: fileURL as URL)
        playerItem = AVPlayerItem(asset: avAsset)
        self.player = AVQueuePlayer.init(items: [self.playerItem])
        if #available(iOS 10.0, *) {
            self.playerLooper = AVPlayerLooper(player: self.player, templateItem: playerItem)
        } else {
            // Fallback on earlier versions
        }
        self.playerLayer = AVPlayerLayer(player: self.player)
        self.adjustPlayerLayer()
        self.player.play()
    }
    
    override func viewDidLayoutSubviews() {
        if let playerLayer = self.playerLayer{
            self.playerLayerView.layoutSubviews()
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
            playerLayer.frame = self.playerLayerView.bounds
            self.playerLayerView.layoutSublayers(of: playerLayer)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.player.remove(self.playerItem)
    }
    
    // 端末の向きがかわったら呼び出される.
    // 端末の向きがかわったら呼び出される.
    func onOrientationChange(notification: NSNotification){
        NSLog("----onOrientationChange内----")
        if let playerLayer = self.playerLayer{
            self.playerLayerView.layoutSubviews()
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
            playerLayer.frame = self.playerLayerView.bounds
            self.playerLayerView.layoutSublayers(of: playerLayer)
        }
    }
    
    func adjustPlayerLayer(){
        if let playerLayer = self.playerLayer{
            playerLayer.videoGravity = AVLayerVideoGravityResizeAspect
            playerLayer.frame = self.playerLayerView.bounds
            self.playerLayerView.layoutSubviews()
            self.playerLayerView.layer.addSublayer(playerLayer)
            self.playerLayerView.layoutSublayers(of: playerLayer)
        }
    }
    
    func play(notification:NSNotification){
        if self.player != nil {
            self.player.play()
        }
    }
}
