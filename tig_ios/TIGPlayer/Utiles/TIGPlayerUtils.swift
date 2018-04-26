//
//  TIGPlayerUtils.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2016/01/16.
//  Copyright © 2016年 MMizogaki. All rights reserved.
//

import UIKit
import MediaPlayer

/// TIGPlayer.TIGPlayerStateを比較するため　==
///
/// - Parameters:
///   - lhs: 左值
///   - rhs: 右值
/// - Returns: 比较结果
/// @ACCESS_PUBLIC
public func ==(lhs: TIGPlayer.TIGPlayerState, rhs: TIGPlayer.TIGPlayerState) -> Bool {
    switch (lhs, rhs) {
    case (.unknown,   .unknown): return true
    case (.readyToPlay,   .readyToPlay): return true
    case (.buffering,   .buffering): return true
    case (.bufferFinished,   .bufferFinished): return true
    case (.playing,   .playing): return true
    case (.seekingForward,   .seekingForward): return true
    case (.seekingBackward,   .seekingBackward): return true
    case (.pause,   .pause): return true
    case (.stopped,   .stopped): return true
    case (.error(let a), .error(let b)) where a == b: return true
    default: return false
    }
}

/// TIGPlayer.TIGPlayerState　!=
///
/// - Parameters:
///   - lhs: 左值
///   - rhs: 右值
/// - Returns: 比较结果
/// @ACCESS_PUBLIC
public func !=(lhs: TIGPlayer.TIGPlayerState, rhs: TIGPlayer.TIGPlayerState) -> Bool {
    return !(lhs == rhs)
}




/// TIGPlayerUtils
/// @ACCESS_PUBLIC
public class TIGPlayerUtils{


    /// 現在位置の時間を時間、分、秒でフォーマットする
    ///
    /// - Parameters:
    /// - position: video current position
    /// - Returns: formated time string
    public static func positionFormatTime( position: TimeInterval) -> String{
        guard !position.isNaN else{
            return ""
        }
        let positionHours = (Int(position) / 3600) % 60
        let positionMinutes = (Int(position) / 60) % 60
        let positionSeconds = Int(position) % 60;

        if positionHours != 0 {

            return String(format: "%01d:%02d:%02d",positionHours,positionMinutes,positionSeconds)
        }
        return String(format:"%02d:%02d",positionMinutes,positionSeconds)
    }


    /// 現在位置の時間/総時間をフォーマットする
    ///
    /// - Parameters:
    /// - position: video current position
    /// - duration: video duration
    /// - Returns: formated time string
    public static func formatTime( position: TimeInterval,duration:TimeInterval) -> String{
        guard !position.isNaN && !duration.isNaN else{
            return ""
        }
        let positionHours = (Int(position) / 3600) % 60
        let positionMinutes = (Int(position) / 60) % 60
        let positionSeconds = Int(position) % 60;

        let durationHours = (Int(duration) / 3600) % 60
        let durationMinutes = (Int(duration) / 60) % 60
        let durationSeconds = Int(duration) % 60

        if durationHours == 0 {

            return String(format: "%02d:%02d/%02d:%02d",positionMinutes,positionSeconds,durationMinutes,durationSeconds)
        }

        if positionHours == 0{

            return String(format: "%02d:%02d/%01d:%02d:%02d",positionMinutes,positionSeconds,durationHours,durationMinutes,durationSeconds)
        }

        return String(format: "%01d:%02d:%02d/%01d:%02d:%02d",positionHours,positionMinutes,positionSeconds,durationHours,durationMinutes,durationSeconds)
    }

    /// Viewから ViewController取得
    ///
    /// - Parameter view: view
    /// - Returns: viewController
    public static func viewController(from view: UIView) -> UIViewController? {
        var responder = view as UIResponder
        while let nextResponder = responder.next {
            if (responder is UIViewController) {
                return (responder as! UIViewController)
            }
            responder = nextResponder
        }
        return nil
    }


}
