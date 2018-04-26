//
//  MediaManager.swift
//  TIGPlayerExample
//
//  Created by MMizogaki on 2016/01/16.
//  Copyright © 2016年 MMizogaki. All rights reserved.
//

import UIKit
import TIGPlayer

/// メディア管理者
class MediaManager {
    
     /// TIGPlayer
     var player: TIGPlayer?
    
     /// 動画アイテム
     var mediaItem: MediaItem?
    
     /// 現在選択されているコンテンツ
     var contentView: UIView?

    /// シングルトン
    static let sharedInstance = MediaManager()
    
    /// initializer
    private init(){
        NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidPlayToEnd(_:)), name: NSNotification.Name.TIGPlayerPlaybackDidFinish, object: nil)
    }

    
    /// 動画再生
    ///
    /// - Parameters:
    ///   - url: url
    ///   - contentView: contentView
    ///   - userinfo: userinfo
    func playWideVideo(url: URL, contentView: UIView? = nil, userinfo: [AnyHashable : Any]? = nil) {
        var mediaItem = MediaItem()
        mediaItem.url = url
        self.playWideVideo(mediaItem: mediaItem, contentView: contentView, userinfo: userinfo )
    }

    /// MediaItemを元に動画再生
    ///
    /// - Parameters:
    ///   - mediaItem: mediaItem
    ///   - contentView: contentView
    ///   - userinfo: userinfo
    func playWideVideo(mediaItem: MediaItem, contentView: UIView? = nil , userinfo: [AnyHashable : Any]? = nil ) {
        self.releasePlayer()

        if let skinView = userinfo?["skin"] as? UIView{
            self.player =  TIGPlayer(controlView: skinView, contentsId: userinfo?["contentsId"] as? String)
        }else{
            self.player = TIGPlayer(contentsId: userinfo?["contentsId"] as? String)
        }

        self.contentView = contentView
        self.player!.playWithURL(mediaItem.url! , contentView: self.contentView)
    }

    /// 動画リソース解放
    func releasePlayer(){
        self.player?.computedPlayerView.removeFromSuperview()
        self.player = nil
        self.contentView = nil
        self.mediaItem = nil
    }

    /// 動画の再生が終了したら動画リソース解放
    ///
    /// - Parameter notifiaction: notifiaction
    @objc func playerDidPlayToEnd(_ notifiaction: Notification) {
        self.releasePlayer()
        NotificationCenter.default.post(name: .showStatusBar, object: self, userInfo: nil)
    }
}

/// @ACCESS_PUBLIC
public extension Notification.Name {
    static let hideStatusBar = Notification.Name(rawValue: "HideStatusBar")
    static let showStatusBar = Notification.Name(rawValue: "ShowStatusBar")
}
