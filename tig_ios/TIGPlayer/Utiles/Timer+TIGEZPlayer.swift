//
//  NSTimer+TIGPlayer.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2016/01/16.
//  Copyright © 2016年 MMizogaki. All rights reserved.
//

import Foundation

// MARK: - Timer
/// @ACCESS_PUBLIC
public extension Timer {

    /// 指定した時間間隔でタイマー生成
    ///
    /// - Parameters:
    ///   - timeInterval: timeInterval
    ///   - block: block
    ///   - repeats: repeats
    /// - Returns: Timer
    public class func timerWithTimeInterval(_ timeInterval: TimeInterval, block: ()->(),  repeats: Bool) -> Timer{

        TIGLog.verbose(message:"Extension NSTimer")
        TIGLog.debug(message:"Timer", anyObject: timeInterval)
        return Timer(timeInterval: timeInterval, target: self, selector: #selector(Timer.executeBlockWithTimer(_:)), userInfo: block, repeats: repeats)
    }

    /// タイマーに保存されている関数を実行
    ///
    /// - Parameter timer: timer description
    @objc private class func executeBlockWithTimer(_ timer: Timer){
        let block: ()->() = timer.userInfo as! ()->()
        block()
    }
}
