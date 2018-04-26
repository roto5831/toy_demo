//
//  TIGAnalytics.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/07/28.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

/// TIGPlayerAnalytics補完
/// @ACCESS_PUBLIC
public protocol TIGAnalyticsComplement:class{
    
    /// 現在の再生時間がデータ送信時に必要
    ///
    /// - Returns: CurrentTime
    func getCurrentTime()->NSDecimalNumber
    
    /// TIGPlayerの情報がデータ送信時に必要
    ///
    /// - Returns: player
    func getPlayer()->TIGPlayer?
}

/// TIGPlayerAnalytics
/// google analyticsにデータを送信する
/// サーバーに置かれたhtmlファイルを取得しそこに記述されたjsを実行
/// @ACCESS_OPEN
open class TIGAnalytics: UIWebView,UIWebViewDelegate {
    
    /// TIGNotification
    let tigNotifi = TIGNotification()
    
    /// TIGPlayerAnalytics補完
    weak var analyticsComp:TIGAnalyticsComplement?
    
    /// ロード中の数
    var webViewLoadingCount:Int = 0
    
    /// ロード中か
    var isWebViewLoading = false
    
    /// 画面に表示しないのでframeは常に0
    ///
    /// - Parameter frame: frame
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        self.delegate = self
    }
    
    
    /// 画面に表示しないのでframeは常に0
    ///
    /// - Parameter frame: frame
    init(){
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        self.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        self.delegate = self
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ///設定
    open func config(contentsId:String){
        let req = URLRequest(url: URL(string: "\(Router.workerToolHost)\(Router.path.analytics.rawValue)?contentsId=\(contentsId)")!)
        self.loadRequest(req as URLRequest)
        
        self.webViewLoadingCount = 0
        self.isWebViewLoading = true
        
        enableNotification()
    }
    
    ///通知の受付を有効に
    open func enableNotification(){
        disableNotification()
        
        self.tigNotifi.observe(TIGNotification.linkout) { notification in
            self.sendLinkoutEvent(sender: notification)
        }
        
        guard let analyticsComp = self.analyticsComp ,
            let player = analyticsComp.getPlayer() else{
                return
        }
        self.tigNotifi.observe(TIGNotification.play) { _ in
            self.sendPlayEvent()
        }
        self.tigNotifi.observe(TIGNotification.stop) { _ in
            self.sendStopEvent(currentTime: analyticsComp.getCurrentTime())
        }
        self.tigNotifi.observe(TIGNotification.tap) { [unowned player] notification in
            self.sendTapEvent(sender: notification, currentTime: analyticsComp.getCurrentTime(), player: player)
        }
        self.tigNotifi.observe(TIGNotification.stock) { [unowned player] notification in
            self.sendStockEvent(sender: notification, currentTime: analyticsComp.getCurrentTime(), player: player)
        }
    }
    
    ///通知の受付を無効に
    open func disableNotification(){
        self.tigNotifi.removeAll()
    }
    
    /// 現在時間を文字列に変換
    ///
    /// - Parameter currentTime: NSDecimalNumber
    /// - Returns: currentTimeStr
    func makeTimeString(_ currentTime: NSDecimalNumber) -> String {
        let mCurrentTime = currentTime.doubleValue
        var hour = 0
        if mCurrentTime >= 60 * 60 {
            hour = Int(mCurrentTime / (60 * 60))
        }
        let minutes = Int((mCurrentTime - Double(hour * (60 * 60))) / 60)
        let seconds = Int(mCurrentTime) - (hour * (60 * 60)) - (minutes * 60)
        let mSecDecimal = mCurrentTime - Double(hour * (60 * 60)) - Double(minutes * 60) - Double(seconds)
        let mSecInt = Int (mSecDecimal * 10.0)
        
        if hour != 0 {
            return String(format: "%02d", hour) + ":" + String(format: "%02d", minutes) + ":" + String(format: "%02d", seconds) + "." + String(format: "%01d", mSecInt)
        } else {
            return String(format: "%02d", minutes) + ":" + String(format: "%02d", seconds) + "." + String(format: "%01d", mSecInt)
        }
    }
    
    
    /// playerの状態を取得
    ///
    /// - Parameter player: TIGPlayer
    /// - Returns: player state
    func getPlayState(_ player:TIGPlayer) -> String {
        if player.isPlaying {
            return "playing"
        }
        
        return "paused"
    }
    
    
    /// TIGObject modeを取得
    ///
    /// - Returns: TIGObject mode
    func getModeType() -> String {
        if ModeManager.getCloseMode() {
            return "close"
        } else {
            return "blink"
        }
    }
    
    
    /// playEvent
    func sendPlayEvent() {
        self.evaluatingJavaScript(from: "tigAnalytics.playEvent()")
    }
    
    /// tapEvent
    ///
    /// - Parameters:
    ///   - sender: Notification
    ///   - currentTime: currentTime
    ///   - player: TIGPlayer
    func sendTapEvent(sender: Notification,currentTime: NSDecimalNumber,player:TIGPlayer) {
        if sender.userInfo == nil {
            return
        }
        
        let userInfo = sender.userInfo?["TIGNotificationpayloadkey"] as! [String: Any]
        let time = makeTimeString(currentTime)
        let playState = getPlayState(player)
        let modeType = getModeType()
        guard
            let x = userInfo["x"],
            let y = userInfo["y"],
            let itemId = userInfo["itemId"]
        else{
            return
        }
        self.evaluatingJavaScript(from: "tigAnalytics.tapEvent('\(x)', '\(y)', '\(time)', '\(playState)', '\(modeType)', '\(itemId)')")
    }
    
    
    /// stockEvent
    ///
    /// - Parameters:
    ///   - sender: Notification
    ///   - currentTime: currentTime
    ///   - player: TIGPlayer
    func sendStockEvent(sender: Notification,currentTime: NSDecimalNumber,player:TIGPlayer) {
        if sender.userInfo == nil {
            return
        }
        
        let userInfo = sender.userInfo?["TIGNotificationpayloadkey"] as! [String: Any]
        let time = makeTimeString(currentTime)
        let playState = getPlayState(player)
        let modeType = getModeType()
        guard
            let x = userInfo["x"],
            let y = userInfo["y"],
            let itemId = userInfo["itemId"]
        else{
            return
        }
        self.evaluatingJavaScript(from: "tigAnalytics.stockEvent('\(x)', '\(y)', '\(time)', '\(playState)', '\(modeType)', '\(itemId)')")
    }
    
    /// linkoutEvent
    ///
    /// - Parameter sender: Notification
    func sendLinkoutEvent(sender: Notification) {
        if sender.userInfo == nil {
            return
        }
        
        let userInfo = sender.userInfo?["TIGNotificationpayloadkey"] as! [String: Any]
        guard
            let scene = userInfo["scene"],
            let url = userInfo["url"],
            let itemId = userInfo["itemId"]
        else{
            return
        }
        self.evaluatingJavaScript(from: "tigAnalytics.linkOutEvent('\(scene)','\(itemId)','\(url)')")
    }
    
    
    /// stopEvent
    ///
    /// - Parameter currentTime: currentTime
    func sendStopEvent(currentTime: NSDecimalNumber) {
        let time = makeTimeString(currentTime)
        
        self.evaluatingJavaScript(from: "tigAnalytics.stopEvent('\(time)')")
    }
    
    /// JavaScriptの実行
    func evaluatingJavaScript(from script: String, retryCount:Int, offsetTime:Int) {
        if retryCount == 0 {
            return
        }
        
        if self.isWebViewLoading {
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(offsetTime)) {
                self.evaluatingJavaScript(from: script, retryCount: retryCount - 1, offsetTime: offsetTime * 2)
            }
        } else {
            self.stringByEvaluatingJavaScript(from: script)
        }
    }
    
    func evaluatingJavaScript(from script: String) {
        self.evaluatingJavaScript(from: script, retryCount: 5, offsetTime: 100)
    }
    
    // MARK: UIWebViewDelegate
    public func webViewDidStartLoad(_ webView: UIWebView) {
        self.webViewLoadingCount += 1
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        self.webViewLoadingCount -= 1
        self.isWebViewLoading = self.webViewLoadingCount > 0
    }
    
    public func webView(_ webView: UIWebView, didFailLoadWithError error: Error) {
        self.webViewLoadingCount -= 1
        self.isWebViewLoading = self.webViewLoadingCount > 0
        print(error)
    }
}
