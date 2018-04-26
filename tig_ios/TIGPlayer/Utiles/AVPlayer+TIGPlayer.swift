//
//  AVPlayer+TIGPlayer.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/1/12.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import AVFoundation

// MARK: - AVPlayer
/// @ACCESS_PUBLIC
public extension AVPlayer {

    /// 再生総時間
    public var duration: TimeInterval? {
        if let  duration = self.currentItem?.duration  {
            return CMTimeGetSeconds(duration)
        }
        return nil
    }

    /// 現在の時間
    public var currentTime: TimeInterval? {
            return CMTimeGetSeconds(self.currentTime())
    }

}
