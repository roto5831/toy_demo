//
//  TIGConstants.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/04/06.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import Foundation

/// TIG定数
class TIGConstants: NSObject {}

/// 端末情報
/// @ACCESS_PUBLIC
public let deviceInfo = DeviceInfo()

// MARK: - Notification.Name
/// @ACCESS_PUBLIC
public extension Notification.Name {
    static let TIGPlayerPlaybackDidFinish = Notification.Name(rawValue: "com.TIGPlayer.TIGPlayerPlaybackDidFinish")
}

// MARK: - Notification
extension Notification {
    struct Key {
        static let PlaybackDidFinishReasonKey = "TIGPlayerPlaybackDidFinishReasonKey"
    }
}


// MARK: - TIGPlayer
extension TIGPlayer {

    /// エラー
    ///
    /// - invalidContentURL: invalidContentURL
    /// - playerFail: playerFail
    public enum TIGPlayerError: Error {
        case invalidContentURL
        case playerFail
    }

    /// 状態
    ///
    /// - unknown:
    /// - error:
    /// - readyToPlay:
    /// - buffering:
    /// - bufferFinished:
    /// - playing:
    /// - seekingForward:
    /// - seekingBackward:
    /// - pause:
    /// - stopped:
    public enum TIGPlayerState {
        case unknown
        case error(TIGPlayer.TIGPlayerError)
        case readyToPlay
        case buffering
        case bufferFinished
        case playing
        case seekingForward
        case seekingBackward
        case pause
        case stopped
    }

    /// 表示モード
    ///
    /// - None: None
    /// - Wide: Wide
    /// - Wipe: Wipe
    public enum TIGPlayerDisplayMode  {
        case None
        case Wide
        case Wipe
    }

    ///layer領域でどのようにvideoが縮尺、伸び縮みするか
    ///
    /// - aspect: aspect
    /// - aspectFill: aspectFill
    /// - scaleFill: scaleFill
    public enum TIGPlayerVideoGravity : String {
        case aspect = "AVLayerVideoGravityResizeAspect"
        case aspectFill = "AVLayerVideoGravityResizeAspectFill"
        case scaleFill = "AVLayerVideoGravityResize"
    }

    /// 再生終了理由
    ///
    /// - playbackEndTime: playbackEndTime
    /// - playbackError: playbackError
    /// - stopByUser: stopByUser
    public enum TIGPlayerPlaybackDidFinishReason  {
        case playbackEndTime
        case playbackError
        case stopByUser
    }
}

// MARK: - PersistentManager
extension PersistentManager {

    /// Persistent定数
    public struct PersistentCosnt {

        /// column Key
        public static let PrimaryKeyColumn = "key"

        /// Persistent PrimaryKey
        ///
        /// - CurrentContent: 現在再生中のコンテント
        /// - BlinkMode: blink
        /// - CloseMode: close
        public enum PrimaryKey:String{
            case CurrentContent = "CurrentContent"
            case BlinkMode = "Blink"
            case CloseMode = "Close"
        }
    }
}

// MARK: - TIGNotification
extension TIGNotification {


    /// Notification payload key
    public static let payload = "TIGNotificationpayloadkey"

    /// Notification Key
    public static let stock     = Notification.Name(rawValue:"stockTIGNotification")
    public static let wipe      = Notification.Name(rawValue:"wipeTIGNotification")
    public static let markClose = Notification.Name(rawValue:"markCloseTIGNotification")
    public static let markHide  = Notification.Name(rawValue:"markHideTIGNotification")
    public static let markBlink = Notification.Name(rawValue:"markBlinkTIGNotification")
    public static let markOpen  = Notification.Name(rawValue:"markOpenTIGNotification")
    public static let dispArrow = Notification.Name(rawValue:"dispArrowTIGNotification")
    public static let hideArrow = Notification.Name(rawValue:"hideArrowTIGNotification")
    public static let hiddenBar = Notification.Name(rawValue:"hidenBarTIGNotification")
    public static let showBar = Notification.Name(rawValue:"showBarTIGNotification")
    public static let toggleBar = Notification.Name(rawValue:"toggleBarTIGNotification")
    public static let toggleMode = Notification.Name(rawValue:"toggleModeTIGNotification")
    public static let fadeInOutStockButton = Notification.Name(rawValue:"fadeInOutStockButtonTIGNotification")
    public static let hideTopCtr = Notification.Name(rawValue:"hideTopCtrTIGNotification")
    public static let blinkMode = Notification.Name(rawValue:"blinkMode")
    public static let closeMode = Notification.Name(rawValue:"closeMode")
    public static let play = Notification.Name(rawValue: "playTIGNotification")
    public static let tap = Notification.Name(rawValue: "tapTIGNotification")
    public static let linkout = Notification.Name(rawValue: "linkoutTIGNotification")
    public static let stop = Notification.Name(rawValue: "stopTIGNotification")
    public static let tigAnimaStart = Notification.Name(rawValue: "animaStartNotification")
    public static let tigAnimaStop = Notification.Name(rawValue: "animaStopNotification")
    public static let tigAnimaCancel = Notification.Name(rawValue: "animaCancelNotification")
    public static let replay = Notification.Name(rawValue: "replayTIGNotification")
}

// MARK: - TIGObjectAreaView
extension TIGObjectAreaView {

    /// 長押しエリア
    static let tapArea:CGFloat = 70

    /// 長押し時間
    static let pressDuration:CFTimeInterval = 0.0

    /// Drag状態
    ///
    /// - noDragging: Defo
    /// - dragging: Dragging
    public enum dragState {
        case noDragging
        case dragging
    }

    /// Swipe状態
    ///
    /// - noSwiping: Defo
    /// - swiping: Drag & Swip
    enum swipState {
        case noSwiping
        case swiping
    }

}

// MARK: - TIGPlayerControlButton
extension TIGPlayerControlButton {

    /// 停止画像
    static let stopImage:UIImage = UIImage(named:"Stop",
                                           in: Bundle(for:TIGPlayerWideControlView.self),
                                           compatibleWith: nil)!

    /// 再生画像
    static let playImage:UIImage = UIImage(named:"Play",
                                           in: Bundle(for:TIGPlayerWideControlView.self),
                                           compatibleWith: nil)!
    
    /// リプレイ画像
    static let replayImage:UIImage = UIImage(named:"replay",
                                           in: Bundle(for:TIGPlayerWideControlView.self),
                                           compatibleWith: nil)!
}

// MARK: -TIGPlayerModeButton
extension TIGPlayerModeButton{
    /// mode
    ///
    /// - blink: blink
    /// - close: close
    public enum mode{
        case blink
        case close
    }
    
    /// closeモード画像
    static let closeModeImage:UIImage = UIImage(named:"ModeClose",
                                                in: Bundle(for:TIGPlayerModeButton.self),
                                                compatibleWith: nil)!
    /// blinkモード画像
    static let blinkModeImage:UIImage = UIImage(named:"Tig",
                                                in: Bundle(for:TIGPlayerModeButton.self),
                                                compatibleWith: nil)!
    /// blink onモード画像
    static let blinkOnImage:UIImage = UIImage(named:"BlinkOn",
                                                in: Bundle(for:TIGPlayerModeButton.self),
                                                compatibleWith: nil)!
    /// blink offモード画像
    static let blinkOffImage:UIImage = UIImage(named:"BlinkOff",
                                              in: Bundle(for:TIGPlayerModeButton.self),
                                              compatibleWith: nil)!
}

// MARK: - TIGStockView
extension TIGStockView {

    /// showingMode
    ///
    /// - dispearAuto:
    /// - keepShowing:
//    public enum showingMode{
//        case disappearAuto
//        case keepShowing
//    }
    
    /// アニメーション時間
    static let duration:TimeInterval = 0.16

    /// ストックエリアが閉じるまでの時間
    static let closeTime = 4

    /// ストックボタン画像
    static let listItemImage:UIImage = UIImage(named:"ListButton",
                                               in: Bundle(for:TIGPlayerWideControlView.self),
                                               compatibleWith: nil)!
    /// stockListView横幅調整距離
    static let marginSpaceHorizontal:CGFloat = 16
    
    /// stockListView高さ調整距離
    static let marginSpaceVertical:CGFloat = 23
    
    /// ストックエリア正常横さ、iPhone x横向き画面時の横さ
    static let widthOfiPhonexLandscape:CGFloat = 100
    
    /// ストックリストビュー座標
    static let positionOfStockListView:(x:CGFloat, y:CGFloat) = (8, 15)
    
    /// ストックエリア横幅
    static let areaWidth = deviceInfo.bounds.longerSide * metaSize.getRatioInBetween(left: metaSize.s_square, and: metaSize.m_square)
}

// MARK: - TIGStockListCell
extension TIGStockListCell{
    static let size = deviceInfo.bounds.longerSide * metaSize.getRatio(metaSize.s_square.rawValue)
}

extension ModeManager {

    ///close Flag:storageから取得できない場合
    static let closeModeDefo:Bool = false
    ///blink Flag:storageから取得できない場合
    static let blinkModeDefo:Bool = true
}

// MARK: - TIGObjectThumbnail
extension TIGObjectThumbnail {
    
    /// サムネイルサイズ
    static var thumbnailSize:CGRect{
        get{
            return CGRect(x:0,y:0,width: 96,height:96)
        }
    }
    
    /// サムネイルラベルサイズ
    static let thumbnailLabelSize = CGRect(x:0,y:-20,width: 96,height:20)
}

// MARK: - TIGObjectMarkViewd
extension TIGObjectMarkView {
    /// とりあえずのサイズ
    static let baseSize = CGSize(width:80,height:26)

    /// 吹き出し部分のサイズ
    static let triangleSize = CGSize(width:12,height:8)
    
    /// フォントサイズ
    static let fontSize:CGFloat = 10
    
    /// 吹き出しとラベルのマージン
    static let balloonMargin:CGFloat = 4
    
    /// 最大文字数
    static let maxStringLength = 20
    
    /// モード
    ///
    /// - close: mode
    /// - blink: mode
    public enum modeState {
        case close
        case blink
    }
}

// MARK: - TIGObjectMoveView
extension TIGObjectMoveView {

    /// アニメーション時間
    static let duration: TimeInterval = 0.1
}

extension TIGObjectStockPointer{
    /// サムネイルラベルサイズ
    static let arrowFrame = CGRect(x:TIGObjectThumbnail.thumbnailSize.origin.x + TIGObjectThumbnail.thumbnailSize.width,
                                   y:TIGObjectThumbnail.thumbnailSize.origin.y + (TIGObjectThumbnail.thumbnailSize.height/2 - 15),
                                   width:30,
                                   height:30)
}

// MARK: - TIGObjectRenderView
extension TIGObjectRenderView{
    /// 一定時間以上長押し下場合はフッター表示させない
    static let tooLongPressToShowBar:Double = 3.0

}

// MARK: - TIGPlayerLoading
extension TIGPlayerLoading{
    static let side = deviceInfo.bounds.longerSide/6
}

// MARK: - TIGPlayerShareButton
extension TIGPlayerShareButton{
    static let side = deviceInfo.bounds.longerSide/8
}

/// TIG object meta size
///
/// - s: 64
/// - m: 96
/// - l: 128
enum metaSize:Int{
    case s_square = 0
    case m_square = 1
    case l_square = 2
    case ll_square = 3
    
    case s_land = 4
    case m_land = 5
    case l_land = 6
    case ll_land = 7
    
    case s_port = 8
    case m_port = 9
    case l_port = 10
    case ll_port = 11
    
    static func getRatioInBetween(left:metaSize,and right:metaSize)->CGFloat{
        return (getRatio(left.rawValue) + getRatio(right.rawValue))/2
    }
    
    static func getRatio(_ meta: Int)->CGFloat{
        switch meta{
        case metaSize.s_square.rawValue, metaSize.s_land.rawValue, metaSize.s_port.rawValue:
            return 0.072
        case metaSize.m_square.rawValue, metaSize.m_land.rawValue, metaSize.m_port.rawValue:
            return 0.108
        case metaSize.l_square.rawValue, metaSize.l_land.rawValue, metaSize.l_port.rawValue:
            return 0.145
        case metaSize.ll_square.rawValue, metaSize.ll_land.rawValue, metaSize.ll_port.rawValue:
            return 0.216
        default:
            return 0.072
        }
    }
    
    static func getSizeDependsOn(_ meta: Int,videoSize:CGRect? = nil) -> CGSize{
        if let videoSize = videoSize{
            let ratio = getRatio(meta)

            switch meta{
            case metaSize.s_square.rawValue, metaSize.m_square.rawValue, metaSize.l_square.rawValue, metaSize.ll_square.rawValue:
                return CGSize(width: videoSize.longerSide * ratio, height:videoSize.longerSide * ratio)
            case metaSize.s_land.rawValue, metaSize.m_land.rawValue, metaSize.l_land.rawValue, metaSize.ll_land.rawValue:
                return CGSize(width: videoSize.longerSide * ratio * 1.5, height:videoSize.longerSide * ratio)
            case metaSize.s_port.rawValue, metaSize.m_port.rawValue, metaSize.l_port.rawValue, metaSize.ll_port.rawValue:
                return CGSize(width: videoSize.longerSide * ratio, height:videoSize.longerSide * ratio * 1.5)
            default:
                return CGSize(width: videoSize.longerSide * ratio, height:videoSize.longerSide * ratio)
            }
        }
        
        switch meta{
        case metaSize.s_square.rawValue:
            return CGSize(width: 64, height: 64)
        case metaSize.m_square.rawValue:
            return CGSize(width: 96, height: 96)
        case metaSize.l_square.rawValue:
            return CGSize(width: 128, height: 128)
        case metaSize.ll_square.rawValue:
            return CGSize(width: 192, height: 192)
        case metaSize.s_land.rawValue:
            return CGSize(width: 96, height: 64)
        case metaSize.m_land.rawValue:
            return CGSize(width: 144, height: 96)
        case metaSize.l_land.rawValue:
            return CGSize(width: 192, height: 128)
        case metaSize.ll_land.rawValue:
            return CGSize(width: 288, height: 192)
        case metaSize.s_port.rawValue:
            return CGSize(width: 64, height: 96)
        case metaSize.m_port.rawValue:
            return CGSize(width: 96, height: 144)
        case metaSize.l_port.rawValue:
            return CGSize(width: 128, height: 192)
        case metaSize.ll_port.rawValue:
            return CGSize(width: 192, height: 288)
        default:
            return CGSize(width: 64, height: 64)
        }
    }
}

// MARK: - TIGPlayerWideControlView
extension TIGPlayerWideControlView {
    /// モードボタンの右側のマージン
    static let modeButtonRightMargin:CGFloat = 9


}
