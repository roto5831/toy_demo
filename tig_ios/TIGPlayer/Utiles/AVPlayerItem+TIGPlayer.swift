//
//  AVPlayerItem+TIGPlayer.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2016/01/16.
//  Copyright © 2016年 MMizogaki. All rights reserved.
//

import AVFoundation

// MARK: - AVPlayerItem
/// @ACCESS_PUBLIC
public extension AVPlayerItem {

    /// バッファー時間
    public var bufferDuration: TimeInterval? {
        if  let first = self.loadedTimeRanges.first {
            let timeRange = first.timeRangeValue
            let startSeconds = CMTimeGetSeconds(timeRange.start)
            let durationSecound = CMTimeGetSeconds(timeRange.duration)
            let result = startSeconds + durationSecound
            return result
        }
        return nil
    }
}
