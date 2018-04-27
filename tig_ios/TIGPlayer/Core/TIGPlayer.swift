//
//  TIGPlayer.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2016/01/16.
//  Copyright © 2016年 MMizogaki. All rights reserved.
//

import Foundation
import AVFoundation
import RealmSwift

/// TIGPlayerDelegate TIGPlayerを操作するのに必要な規約を定義
/// controllviewがこの規約に従う
/// @ACCESS_PUBLIC
public protocol TIGPlayerDelegate : class {
    
    /// 移譲先に対してTIGPlayerの状態が変更されたことを伝える
    /// 状態が一旦変更されたら、移譲先は現在の状態に基づいて適切な処理を行う
    /// ※処理を集約するために、状態に基づいた条件分岐を用いて実装することが推奨される
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - state: TIGPlayer.TIGPlayerState
    func player(_ player: TIGPlayer ,playerStateDidChange state: TIGPlayer.TIGPlayerState)

    /// 移譲先に対してTIGPlayerの表示モードが変更されたことを伝える

    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - state: TIGPlayer.TIGPlayerDisplayMode
    func player(_ player: TIGPlayer ,playerDisplayModeDidChange displayMode: TIGPlayer.TIGPlayerDisplayMode)

    /// 移譲先に対してTIGPlayerの再生データのバッファが変更されたことを伝える
    ///
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - bufferDuration: AVPlayerItemのバッファ
    ///   - totalDuration: 総時間
    func player(_ player: TIGPlayer ,bufferDurationDidChange  bufferDuration: TimeInterval , totalDuration: TimeInterval)

    /// 移譲先に対してTIGPlayerの現在の再生時間を伝える
    /// 現在の再生時間に基づいて、何か処理をする
    ///
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - currentTime: 現在の再生時時間
    ///   - duration: 総時間
    func player(_ player: TIGPlayer , currentTime   : TimeInterval , duration: TimeInterval)

    /// 移譲先に対してTIGPlayerのローディングを表示するかどうかを伝える。
    /// 移譲先ではローディングの実装が必要
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - showLoading: ローディング表示するかどうか
    func player(_ player: TIGPlayer ,showLoading: Bool)
    
    /// 移譲先に対して端末方向が変化したことを伝える。
    ///
    /// - Parameters:
    ///   - player: player
    ///   - orientationType: DeviceInfo.orientationType
    func player(_ player: TIGPlayer ,orientationDidChange orientationType: DeviceInfo.orientationType)
}

/// TIGPlayer AVPlayerのwrapper
/// @ACCESS_OPEN
open class TIGPlayer: NSObject, UIWebViewDelegate {
    
    /// player layer領域でどのようにvideoが縮尺、伸び縮みするか
    open var videoGravity = TIGPlayerVideoGravity.aspect{
        didSet {
            if let layer = self.playerView?.layer as? AVPlayerLayer{
                layer.videoGravity = videoGravity.rawValue
            }
        }
    }
    
    /// アイテムに設定されているURLをロードするWebView
    open var myWebView : UIWebView = UIWebView()
    
    /// webViewNaviBar
    open var webViewNaviBar: UIView = UIView()
    
    /// 一個前のページへ
    open var backButton: UIButton!
    
    /// 一個後のページへ
    open var forwardButton: UIButton!
    
    /// Safariで開く
    open var openInSafariButton: UIButton!
    
    /// webViewに表示するTopページのURL
    open var loadingURLInWeb:URL?
    
    /// 今ローディングしているページ
    open var currentLoadingPage:URL?
    
    /// 外部での再生を許可するかどうか
    open var allowsExternalPlayback = true{
        didSet{
            guard let avplayer = self.player else {
                return
            }
            avplayer.allowsExternalPlayback = allowsExternalPlayback
        }
    }

    /// 外部再生モードになっているかどうか
    open var isExternalPlaybackActive: Bool  {
        guard let avplayer = self.player else {
            return false
        }
        return  avplayer.isExternalPlaybackActive
    }

    
    /// player再生時間の観測者
    /// 観測時間の単位は0.１秒　PeriodicTimeObserverを使用することで自由に設定が可能
    private var timeObserver: Any?
    
    
    /// contentURL
    open private(set)  var contentURL :URL?{
        didSet{
            guard let url = contentURL else {
                return
            }
            self.isM3U8 = url.absoluteString.hasSuffix(".m3u8")
        }
    }
    
    /// AVPlayer
    open private(set)  var player: AVPlayer?
    
    /// AVAsset
    //imageGeneratorはローカル再生動画限定のプレビュー生成者
    open private(set)  var playerasset: AVAsset?{
        didSet{
            if oldValue != playerasset{
                if playerasset != nil {
                    self.imageGenerator = AVAssetImageGenerator(asset: playerasset!)
                }else{
                    self.imageGenerator = nil
                }
            }
        }
    }
    
    /// AVPlayerItem
    /// playerItemが切り替わるたびにObserverを解放して新たにセット
    open private(set)  var playerItem: AVPlayerItem?{
        willSet{
            if playerItem != newValue{
                if let item = playerItem{
                    item.removeObserver(self, forKeyPath: "status")
                    item.removeObserver(self, forKeyPath: "loadedTimeRanges")
                    item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
                    item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
                }
            }
        }
        didSet {
            if playerItem != oldValue{
                if let item = playerItem{
                    item.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
                    item.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.new, context: nil)
                    item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
                    item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
                }
            }
        }
    }
    
    /// ローカル再生動画限定のプレビュー生成者:本仕様上必要ないが、ローカル版動画でプレビューを生成するのに使用可能
    open private(set)  var imageGenerator: AVAssetImageGenerator?
    
    /// HTTP Live Streaming対応拡張子かどうか
    open private(set)  var isM3U8 = false
    
    /// 再生時間が数値として扱えないかどうか
    open  var isLive: Bool? {
        if let duration = self.duration {
            return duration.isNaN
        }
        return nil
    }
    
    /// TIGPlayerを制御するviewのgetter
    /// wide,none mode時はTIGPlayerWideControlView
    /// wipe mode時はTIGPlayerWipeView
    open  var controlView : UIView?{
        
        switch self.displayMode {
        case .Wide:
            return self.controlViewForWide
        case .Wipe:
            return self.controlViewForWipe
        case .None:
            return self.controlViewForWide
        }
    }
    
    /// wide mode時のcontrolView
    weak open  var controlViewForWide : UIView?
    
    /// wipe mode時のcontrolView
    weak open  var controlViewForWipe : UIView?
    
    /// TIGPlayerとその制御を担当するcontrolViewのwrapper
    private var playerView: TIGPlayerView?
    
    /// TIGPlayerViewのgetter
    open var computedPlayerView: UIView{
        if self.playerView == nil{
            self.playerView = TIGPlayerView(controlView: self.controlView)
        }
        return self.playerView!
    }
    
    /// contentView
    /// 階層:contentView
    ///       TIGPlayerView:player&cntrollviewのwrapper
    ///       webView:wipeモード時のサイトurlをload
    open weak var contentView: UIView?
    
    open var wipeContainer: TIGPlayerWipeContainer?
    open var wipeContainerRootViewController: TIGPlayerWipeContainerRootViewController?
    
    /// TIGPlayerの状態
    /// 状態が切り替わるたびにplayerStateDidChangeを呼び出す
    /// AVPlayerItemで監視されている状態に対してのwrapper
    open fileprivate(set) var state = TIGPlayer.TIGPlayerState.unknown{
        didSet{
            self.previousState = oldValue
            if oldValue != state{
                (self.controlView as? TIGPlayerDelegate)?.player(self, playerStateDidChange: state)
            }
        }
    }
    
    /// 一個前の状態
    open var previousState = TIGPlayer.TIGPlayerState.unknown

    /// 表示モード
    /// 状態が切り替わるたびにplayerDisplayModeDidChangeを呼び出す
    open private(set)  var displayMode = TIGPlayerDisplayMode.None{
        didSet{
            if oldValue != displayMode{
                (self.controlView as? TIGPlayerDelegate)?.player(self, playerDisplayModeDidChange: displayMode)
            }
        }
    }
    
    /// WipeModeかどうか
    open var isDisplayModeWipe:Bool{
        return displayMode == .Wipe
    }
    
    /// 再生中かどうか
    open var isPlaying:Bool{
        guard let player = self.player else {
            return false
        }
        return player.rate > Float(0) && player.error == nil
    }

    /// video総時間
    open var duration: TimeInterval? {
        if let  duration = self.player?.currentItem?.duration  {
            if self.player?.currentItem?.status == .readyToPlay {
                return CMTimeGetSeconds(duration)
            } else{
                return nil
            }
        }
        return nil
    }


    /// videoの現在再生時間
    open var currentTime: TimeInterval? {
        if let  currentTime = self.player?.currentTime() {
            return CMTimeGetSeconds(currentTime)
        }
        return nil

    }

    /// Video再生速度
    open var rate: Float{
        get {
            if let player = self.player {
                return player.rate
            }
            return .nan
        }
        set {
            if let player = self.player {
                player.rate = newValue
            }
        }
    }

    /// モードの設定
    ///
    /// - close: 0
    /// - blink: 1
    open var tigMode = 1{
        didSet{
            if self.controlViewForWide != nil {
                (self.controlViewForWide as? TIGPlayerWideControlView)?.tigMode = tigMode
            }
        }
    }
    /// モード切替の有効・無効
    open var enableToggleMode = true{
        didSet{
            if self.controlViewForWide != nil {
                (self.controlViewForWide as? TIGPlayerWideControlView)?.enableToggleMode = enableToggleMode
            }
        }
    }
    
    /// Shareボタンの表示
    open var showShareButton = false{
        didSet{
            if self.controlViewForWide != nil {
//                (self.controlViewForWide as? TIGPlayerWideControlView)?.showShareButton = showShareButton
            }
        }
    }
    
    /// Wipeの有効・無効
    open var enableWipe = true{
        didSet{
            if self.controlViewForWide != nil {
                (self.controlViewForWide as? TIGPlayerWideControlView)?.enableWipe = enableWipe
            }
        }
    }
    
    /// contentsId
    private(set) var contentsId: String?

    //  モード変更時のアニメーション時間
    var tigAnimatedDuration = 0.3
    
    var presentationVideoSizeCache:Dictionary<String,CGSize> = [:]
    
    /// initializer
    ///
    /// - Parameter contentsId: contentsId
    public init(contentsId: String?) {
        super.init()
        self.contentsId = contentsId
        self.commonInit()
    }

    /// initializer
    ///
    /// - Parameters:
    ///   - controlView: controlView
    ///   - contentsId: contentsId
    public init(controlView: UIView?, contentsId: String?) {
        super.init()
        self.contentsId = contentsId
        if controlView == nil{
            self.controlViewForWide = UIView()
        }else{
            self.controlViewForWide = controlView
        }
        self.commonInit()
    }
    
    /// deinitializer
    deinit {
        self.freeWhenRetuningToMenu()
        self.releasePlayerResource()
        self.controlViewForWide = nil
        self.controlViewForWipe = nil
    }
    
    /// 再生終了
    ///
    /// - Parameter reason: reason 
    open func playbackDidFinish(reason:TIGPlayerPlaybackDidFinishReason) -> Void{
        NotificationCenter.default.post(name: .TIGPlayerPlaybackDidFinish, object: self, userInfo: [Notification.Key.PlaybackDidFinishReasonKey: reason])
    }
    
    /// TIGPlayer再生
    ///　TIGPlayerView,WebViewはここでcontentViewのsubViewに追加
    ///
    /// - Parameters:
    ///   - url: 動画のurl
    ///   - contentView: contentView
    ///   - title: title
    open func playWithURL(_ url: URL,contentView: UIView? = nil, title: String? = nil) {
        self.contentURL = url
        self.prepareToPlay()

        if contentView != nil {
            self.contentView = contentView
            // webViewNaviBar
            self.webViewNaviInitial()
            self.webViewInitial()
            self.contentView!.addSubview(self.computedPlayerView)
            self.computedPlayerView.frame = self.contentView!.bounds
            self.displayMode = .Wide
        }
    }
    
    /// web view control navigation bar初期生成
    func webViewNaviInitial() {
        if self.contentView == nil {
            return
        }
        
        /// webViewNaviTopBar
        self.webViewNaviBar = UIView()
        
        // webViewNavi初期化
        if #available(iOS 11.0, *) {
            if deviceInfo.isIpohneX{
                self.webViewNaviBar.frame = CGRect.init(x: 0,
                                                        y: self.contentView!.safeAreaInsets.top,
                                                        width: deviceInfo.bounds.width,
                                                        height: 44)
            }else{
                self.webViewNaviBar.frame = CGRect.init(x: 0,
                                                        y: 0,
                                                        width: deviceInfo.bounds.width,
                                                        height: 44)
            }
        } else {
            // Fallback on earlier versions
            self.webViewNaviBar.frame = CGRect.init(x: 0,
                                                    y: 0,
                                                    width: deviceInfo.bounds.width,
                                                    height: 44)
        }
        
        self.webViewNaviBar.backgroundColor = UIColor.white
        
        // back button
        self.backButton = UIButton.init(frame: CGRect.init(x: 15,
                                                           y: 0,
                                                           width: 34,
                                                           height: 44))
        let backNormal = UIImage(named: "WebBackNormal", in: Bundle(for:TIGPlayer.self), compatibleWith: nil)!
        let backDisable = UIImage(named: "WebBackDisable", in: Bundle(for:TIGPlayer.self), compatibleWith: nil)!
        self.backButton.setImage(backNormal, for: .normal)
        self.backButton.setImage(backDisable, for: .disabled)
        self.backButton.imageView?.contentMode = UIViewContentMode.scaleToFill
        self.backButton.backgroundColor = UIColor.clear
        self.backButton.addTarget(self, action: #selector(self.goBack), for: UIControlEvents.touchUpInside)
        self.backButton.isEnabled = self.myWebView.canGoBack
        
        // forward button
        self.forwardButton = UIButton.init(frame: CGRect.init(x: self.backButton.frame.origin.x + self.backButton.frame.width + 40,
                                                              y: 0,
                                                              width: 34,
                                                              height: 44))
        let forwardsNormal = UIImage(named: "WebForwardsNormal", in: Bundle(for:TIGPlayer.self), compatibleWith: nil)!
        let forwardsDisable = UIImage(named: "WebForwardsDisable", in: Bundle(for:TIGPlayer.self), compatibleWith: nil)!
        self.forwardButton.setImage(forwardsNormal, for: .normal)
        self.forwardButton.setImage(forwardsDisable, for: .disabled)
        self.forwardButton.imageView?.contentMode = UIViewContentMode.scaleToFill
        self.forwardButton.backgroundColor = UIColor.clear
        self.forwardButton.addTarget(self, action: #selector(self.goForward), for: UIControlEvents.touchUpInside)
        self.forwardButton.isEnabled = self.myWebView.canGoForward
        
        // open in safari button
        self.openInSafariButton = UIButton.init(frame: CGRect.init(x: self.webViewNaviBar.frame.width - 120 - 15,
                                                                   y: 5,
                                                                   width: 120,
                                                                   height: 34))
        self.openInSafariButton.setTitle("Safariで開く", for: .normal)
        self.openInSafariButton.setTitleColor(UIColor(red: 19/255.0, green:144/255.0, blue:255/255.0, alpha:1.0), for: .normal)
        self.openInSafariButton.backgroundColor = UIColor.clear
        self.openInSafariButton.addTarget(self, action: #selector(self.openInSafari), for: UIControlEvents.touchUpInside)
        
        self.openInSafariButton.isHidden = true
        self.openInSafariButton.isEnabled = false
        
        self.webViewNaviBar.addSubview(self.backButton)
        self.webViewNaviBar.addSubview(self.forwardButton)
        self.webViewNaviBar.addSubview(self.openInSafariButton)
        
        self.webViewNaviBar.isHidden = true
        self.webViewNaviBar.isUserInteractionEnabled = false
        
//        self.contentView!.addSubview(self.webViewNaviBar)
    }
    
    /// web view初期生成
    open func webViewInitial(){
        self.myWebView = UIWebView()
        self.myWebView.delegate = self
        if #available(iOS 11.0, *) {
            if deviceInfo.isIpohneX {
                self.myWebView.frame = CGRect(x:0,
                                              y:self.contentView!.safeAreaInsets.top,
                                              width:self.contentView!.frame.size.width,
                                              height:self.contentView!.frame.size.height)
            }else{
                self.myWebView.frame = CGRect(x:0,
                                              y:0,
                                              width:self.contentView!.frame.size.width,
                                              height:self.contentView!.frame.size.height)
            }
        } else {
            self.myWebView.frame = CGRect(x:0,
                                          y:0,
                                          width:self.contentView!.frame.size.width,
                                          height:self.contentView!.frame.size.height)
        }
        self.contentView!.addSubview(self.myWebView)
        self.myWebView.autoresizingMask = [.flexibleHeight, .flexibleWidth,.flexibleLeftMargin,.flexibleTopMargin,.flexibleRightMargin,.flexibleBottomMargin]
    }
    
    /// webView前のページに戻る
    open func goBack() {
        if (self.myWebView.canGoBack) {
            self.myWebView.goBack()
        } else {
        }
    }
    
    /// webView後のページに進む
    open func goForward() {
        if (self.myWebView.canGoForward) {
            self.myWebView.goForward()
        } else {
        }
    }
    
    // WebViewがコンテンツの読み込みを開始した時に呼ばれる
    open func webViewDidStartLoad(_ webView: UIWebView) {
    }
    
    // WebView がコンテンツの読み込みを完了した後に呼ばれる
    open func webViewDidFinishLoad(_ webView: UIWebView) {
        self.currentLoadingPage = webView.request?.url!
        if webView.request?.url?.absoluteString == self.loadingURLInWeb?.absoluteString{
            self.backButton.isEnabled = false
        }else{
            self.backButton.isEnabled = self.myWebView.canGoBack
        }
        self.forwardButton.isEnabled = self.myWebView.canGoForward
    }
    
    // Safariで開く
    open func openInSafari(){
        if let url = self.currentLoadingPage {
            UIApplication.shared.openURL(url)
        }
    }
    
    /// 再生動画切り替え　※未使用
    ///　今後の仕様で動画を再生中に別動画に切替えたいなどがあった場合に残しておく
    /// - Parameters:
    ///   - url: 動画のurl
    ///   - title: title
    open func replaceToPlayWithURL(_ url: URL, title: String? = nil) {
        self.resetPlayerResource()

        self.contentURL = url
 
        guard let url = self.contentURL else {
            self.state = .error(.invalidContentURL)
            return
        }

        self.contentURL = url

        self.playerasset = AVAsset(url: url)

        let keys = ["tracks","duration","commonMetadata","availableMediaCharacteristicsWithMediaSelectionOptions"]
        self.playerItem = AVPlayerItem(asset: self.playerasset!, automaticallyLoadedAssetKeys: keys)
        self.player?.replaceCurrentItem(with: self.playerItem)
    }

    
    /// 状態を再生に切り替える
    open func play(){
        self.state = .playing
        self.player?.play()
    }

    /// 状態をポーズに切り替える
    open func pause(){
        self.state = .pause
        self.player?.pause()
    }

    /// 状態を停止に切り替える
    open func stop(){
        self.state = .stopped
        self.player?.pause()
    }

    /// 停止&解放
    open func stopAndRelease(){
        let lastState = self.state
        self.state = .stopped

        self.myWebView.removeFromSuperview()
//        self.webViewNaviBar.removeFromSuperview()

        self.player?.pause()
        self.freeWhenRetuningToMenu()
        self.releasePlayerResource()
        guard case .error(_) = lastState else{
            self.playbackDidFinish(reason: .stopByUser)
            return
        }
    }
    
    /// 手動解放
    open func freeWhenRetuningToMenu(){
        NotificationCenter.default.removeObserver(self)
        if let controlView = self.playerView?.controlView as? TIGPlayerWideControlView{
            controlView.loading.timer?.invalidate()
            controlView.loading.timer = nil
            controlView.loading.layer.removeAllAnimations()
            controlView.timer?.invalidate()
            controlView.timer = nil
            controlView.renderView?.objectViewList.forEach{ item in
                item.value.areaView?.invalidateTimers()
                item.value.areaView?.clearTimers()
                item.value.areaView?.layer.removeAllAnimations()
                item.value.areaView?.objectMark?.layer.removeAllAnimations()
            }
            controlView.renderView?.itemList = nil
            controlView.renderView?.metaList = nil
            controlView.renderView?.layer.removeAllAnimations()
            controlView.renderView?.removeFromSuperview()
            controlView.renderView = nil
            controlView.stockAreaView.timer?.invalidate()
            controlView.stockAreaView.timer = nil
            controlView.stockAreaView.tigNotification.removeAll()
            controlView.stockAreaView.delegate = nil
            controlView.tigNotifi.removeAll()
            controlView.modeButton?.tigNotification.removeAll()
            controlView.modeButton = nil
            controlView.tigAnalytics.tigNotifi.removeAll()
            controlView.shareButton = nil
        }

    }

    /// playerの再生時間を移動
    ///
    /// - Parameters:
    ///   - time: 移動後の時間
    ///   - completionHandler: seek後の処理
    open func seek(to time: TimeInterval, completionHandler: ((Bool) -> Swift.Void )? = nil){
        guard let player = self.player else {
            return
        }

        let lastState = self.state
        if let currentTime = self.currentTime {
            if currentTime > time {
                self.state = .seekingBackward
            }else if currentTime < time {
                self.state = .seekingForward
            }
        }


        player.seek(to: CMTimeMakeWithSeconds(time,CMTimeScale(NSEC_PER_SEC)), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: {  [weak self]  (finished) in
            guard let weakSelf = self else {
                return
            }
            switch (weakSelf.state) {
            case .seekingBackward,.seekingForward:
                weakSelf.state = lastState
            default: break
            }
            completionHandler?(finished)
        })
    }


    /// 表示モードを変更しているかどうか
    private var isChangingDisplayMode = false


    /// Wide modeに変更
    ///
    /// - Parameters:
    ///   - animated: aniamtionするかどうか
    ///   - completion: completion handller
    open func toWide(animated: Bool = true , completion: ((Bool) -> Swift.Void)? = nil){
        if self.isChangingDisplayMode {
            completion?(false)
            return
        }
        guard self.displayMode == .Wipe else{
            completion?(false)
            return
        }
        guard let contentView = self.contentView else{
            completion?(false)
            return
        }

        func __toWide(){
            guard let wipeContainer = self.wipeContainer  else {
                completion?(false)
                return
            }
            // 一旦web viewのback forwardsボタンを全部非活性化にする
            self.backButton.isEnabled = false
            self.forwardButton.isEnabled = false
            
            // clear loading page url
            self.loadingURLInWeb = nil
            self.currentLoadingPage = nil
            
            wipeContainer.hidden()
            self.isChangingDisplayMode = true
            self.updateCustomView(toDisplayMode: .Wide)
            if animated {
                let rect = wipeContainer.wipeWindow.convert(self.computedPlayerView.frame, to:  UIApplication.shared.keyWindow)
                self.computedPlayerView.removeFromSuperview()
                UIApplication.shared.keyWindow?.addSubview(self.computedPlayerView)
                self.computedPlayerView.frame = rect
                
                UIView.animate(withDuration: tigAnimatedDuration, animations: {
                    self.computedPlayerView.bounds = contentView.bounds
                    self.computedPlayerView.center = contentView.center
                    
                }, completion: {finished in
                    __endToWide(finished: finished)
                })
            }else{
                __endToWide(finished: true)
                
            }
        }
        
        func __endToWide(finished :Bool)  {
            self.computedPlayerView.removeFromSuperview()
            contentView.addSubview(self.computedPlayerView)
            self.computedPlayerView.frame = contentView.bounds

            completion?(finished)
            self.isChangingDisplayMode = false
        }
        
        __toWide()
    }
    
    /// Wipe modeに変更
    ///
    /// - Parameters:
    ///   - animated: aniamtionするかどうか
    ///   - completion: completion handller
    open func toWipe(animated: Bool = true, completion: ((Bool) -> Swift.Void)? = nil) {
        if self.isChangingDisplayMode == true {
            completion?(false)
            return
        }
        guard self.displayMode == .Wide else{
            completion?(false)
            return
        }
        
        func __endtoWipe(finished :Bool)  {
            self.computedPlayerView.removeFromSuperview()
            self.wipeContainerRootViewController?.addVideoView(self.computedPlayerView)
            self.wipeContainer?.show()
            completion?(finished)
            self.isChangingDisplayMode = false
        }
        
        self.configWipeVideo()
        self.isChangingDisplayMode = true
        self.updateCustomView(toDisplayMode: .Wipe)
        if animated{
            let rect = self.contentView!.convert(self.computedPlayerView.frame, to: UIApplication.shared.keyWindow)
            self.computedPlayerView.removeFromSuperview()
            UIApplication.shared.keyWindow?.addSubview(self.computedPlayerView)
            self.computedPlayerView.frame = rect
            UIView.animate(withDuration: tigAnimatedDuration, animations: {
                self.computedPlayerView.bounds = self.wipeContainer!.wipeWindow.bounds
                self.computedPlayerView.center = self.wipeContainer!.wipeWindow.center
            }, completion: {finished in
                __endtoWipe(finished: finished)
            })
        }else{
            __endtoWipe(finished: true)
        }
    }

    /// Wipe containerとcontrollerの設定
    func configWipeVideo(){
        if self.wipeContainerRootViewController == nil {
            self.wipeContainerRootViewController = TIGPlayerWipeContainerRootViewController(nibName: String(describing: TIGPlayerWipeContainerRootViewController.self), bundle: Bundle(for: TIGPlayerWipeContainerRootViewController.self))
            self.wipeContainerRootViewController?.player = self
        }
        if let container = self.wipeContainer{
            container.adjustOrigin()
        }else{
            self.wipeContainer = TIGPlayerWipeContainer(rootViewController: self.wipeContainerRootViewController!)
        }
    }
    
    
    /// 指定したモードに応じたcontrolViewの切替
    ///
    /// - Parameter toDisplayMode: displayMode
    open  func updateCustomView(toDisplayMode: TIGPlayerDisplayMode? = nil){
        var nextDisplayMode = self.displayMode
        if toDisplayMode != nil{
            nextDisplayMode = toDisplayMode!
        }
        switch nextDisplayMode {
        case .Wide:
            if self.playerView?.controlView == nil || self.playerView?.controlView != self.controlViewForWide{
                if self.controlViewForWide == nil {
                    self.controlViewForWide = Bundle(for: TIGPlayerWideControlView.self).loadNibNamed(String(describing: TIGPlayerWideControlView.self), owner: self, options: nil)?.last as? TIGPlayerWideControlView
                    
                    (self.controlViewForWide as? TIGPlayerWideControlView)?.tigMode = self.tigMode
                    (self.controlViewForWide as? TIGPlayerWideControlView)?.enableToggleMode = self.enableToggleMode
//                    (self.controlViewForWide as? TIGPlayerWideControlView)?.showShareButton = self.showShareButton
                    (self.controlViewForWide as? TIGPlayerWideControlView)?.enableWipe = self.enableWipe
                }
            }
            self.playerView?.controlView = self.controlViewForWide

        case .Wipe:
            if self.playerView?.controlView == nil || self.playerView?.controlView != self.controlViewForWipe{
                    if self.controlViewForWipe == nil {
                    self.controlViewForWipe = Bundle(for: TIGPlayerWipeView.self).loadNibNamed(String(describing: TIGPlayerWipeView.self), owner: self, options: nil)?.last as? UIView
                }
            }
            self.playerView?.controlView = self.controlViewForWipe

            break
        case .None:
            if self.controlView == nil {
                    self.controlViewForWide =  Bundle(for: TIGPlayerWideControlView.self).loadNibNamed(String(describing: TIGPlayerWideControlView.self), owner: self, options: nil)?.last as? TIGPlayerWideControlView
                
                (self.controlViewForWide as? TIGPlayerWideControlView)?.tigMode = self.tigMode
                (self.controlViewForWide as? TIGPlayerWideControlView)?.enableToggleMode = self.enableToggleMode
//                (self.controlViewForWide as? TIGPlayerWideControlView)?.showShareButton = self.showShareButton
                (self.controlViewForWide as? TIGPlayerWideControlView)?.enableWipe = self.enableWipe
            }
        }
        self.displayMode = nextDisplayMode
    }

    /// 共通の初期化 controllviewと端末方向の切替を観測
    private func commonInit() {
        self.updateCustomView()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceOrientationDidChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    /// 再生準備
    /// PlayerAsset,Item,TIGPlayerViewの初期化 周期的な再生時間の観測者の登録等
    private func prepareToPlay(){
        guard let url = self.contentURL else {
            self.state = .error(.invalidContentURL)
            return
        }
        self.releasePlayerResource()

        self.playerasset = AVAsset(url: url)

        let keys = ["tracks","duration","commonMetadata","availableMediaCharacteristicsWithMediaSelectionOptions"]
        self.playerItem = AVPlayerItem(asset: self.playerasset!, automaticallyLoadedAssetKeys: keys)
        self.player     = AVPlayer(playerItem: playerItem!)
        self.player!.allowsExternalPlayback = self.allowsExternalPlayback
        if self.playerView == nil {
            self.playerView = TIGPlayerView(controlView: self.controlView )
        }
        (self.playerView?.layer as! AVPlayerLayer).videoGravity = self.videoGravity.rawValue
        self.playerView?.config(player: self)

        (self.controlView as? TIGPlayerDelegate)?.player(self, showLoading: true)
        self.addPlayerItemTimeObserver()
    }


    /// 周期的な再生時間の観測者　0.1秒ごとに観測
    /// controlView (TIGPlayerDelegate)に観測した後の処理を移譲
    private func addPlayerItemTimeObserver(){
        self.timeObserver = self.player?.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.1, CMTimeScale(NSEC_PER_SEC)), queue: DispatchQueue.main, using: {  [weak self] time in

            guard
                let weakSelf = self,
                let currentTime = weakSelf.currentTime,
                let duration = weakSelf.duration,
                !currentTime.isInfinite && !currentTime.isNaN,
                !duration.isInfinite && !duration.isNaN,
                let playerItem = weakSelf.playerItem,
                weakSelf.state != .stopped
            else {
                return
            }
            if !playerItem.isPlaybackLikelyToKeepUp && weakSelf.state == .playing{
                weakSelf.state = .buffering
            }
            
            if playerItem.isPlaybackLikelyToKeepUp && weakSelf.state == .buffering{
                weakSelf.state = .bufferFinished
                weakSelf.state = .playing
            }
            if weakSelf.isPseudoEnd(currentTime: currentTime, duration: duration){
                weakSelf.playerDidPlayToEnd()
                (weakSelf.controlView as? TIGPlayerDelegate)?.player(weakSelf, currentTime: duration, duration: duration)
            }else{
                (weakSelf.controlView as? TIGPlayerDelegate)?.player(weakSelf, currentTime: currentTime, duration: duration)
            }
        })
    }


    /// 擬似の再生時間終了
    /// 再生時間終了すると動画がブラックアウトされてしまうので、0,3秒前を終了とみなす。
    ///
    /// - Parameters:
    ///   - currentTime: currentTime
    ///   - duration: duration
    /// - Returns: floor(currentTime * 10)/10 == floor(duration * 10)/10 - 0.3
    private func isPseudoEnd(currentTime:Double,duration:Double) -> Bool{
        let leftOperand = floor(currentTime * 10)/10
        let rightOperand = floor(duration * 10)/10-0.3
        return String(leftOperand) == String(rightOperand)
    }

    /// PlayerResourceをリセット
    private func resetPlayerResource() {
        self.contentURL = nil
        self.playerasset = nil
        self.playerItem = nil
        self.player?.replaceCurrentItem(with: nil)
        self.playerView?.layer.removeAllAnimations()
        (self.controlView as? TIGPlayerDelegate)?.player(self, bufferDurationDidChange: 0, totalDuration: 0)
        (self.controlView as? TIGPlayerDelegate)?.player(self, currentTime: 0, duration: 0)
    }

    /// PlayerResourceを解放
    private func releasePlayerResource() {
        
        self.playerasset = nil
        self.playerItem = nil
        self.player?.replaceCurrentItem(with: nil)
        self.playerView?.layer.removeAllAnimations()
        self.playerView?.removeFromSuperview()
        self.playerView = nil
        self.wipeContainer = nil
        if self.timeObserver != nil{
            self.player?.removeTimeObserver(self.timeObserver!)
            self.timeObserver = nil
        }
    }
    
    
    /// 画面上に表示されている動画のサイズと座標
    ///
    /// - Returns: videoRect
    open func getVideoRectangle()->CGRect{
        if let layer = self.computedPlayerView.layer as? AVPlayerLayer{
            let videoRect = layer.videoRect
            return videoRect
        }
        return CGRect()
    }
    
    
    /// 実際の動画サイズ
    ///
    /// - Returns: CGSize
    open func getPresentationVideoSize() -> CGSize{
        if let cached = self.presentationVideoSizeCache["PresentationVideoSize"]{
            return cached
        }
        if let player = self.player{
            if let currentItem
                = player.currentItem{
                let actualWidth = currentItem.presentationSize.width
                let actualHeight = currentItem.presentationSize.height
                if actualWidth != 0 && actualHeight != 0{
                    self.presentationVideoSizeCache["PresentationVideoSize"] = CGSize(width: actualWidth, height: actualHeight)
                }
                return CGSize(width: actualWidth, height: actualHeight)
            }
        }
        return CGSize()
    }
    
    /// 妥当な動画サイズかどうか
    open var isValidPresentationVideoSize: Bool{
        let videoSizes = self.getPresentationVideoSize()
        return videoSizes.width != 0 && videoSizes.height != 0
    }
    
    /// 縦用動画
    ///
    /// - Returns: return value description
    open var isVideoForLandscape:Bool{
        let size = getPresentationVideoSize()
        return size.width >= size.height
    }
}

// MARK: - Notification
extension TIGPlayer {
    
    /// playerの再生が終了した
    ///
    /// - Parameter notifiaction: notifiaction
    @objc func playerDidPlayToEnd(_ notifiaction: Notification? = nil) {
        self.stop()
        TIGNotification.post(TIGNotification.showBar)
    }

    /// 端末方向の変更はここで対応
    ///
    /// - Parameter notifiaction: notifiaction
    @objc fileprivate  func deviceOrientationDidChange(_ notifiaction: Notification){
//        if let contentView = self.contentView{
//            if #available(iOS 11.0, *) {
//                if deviceInfo.isIpohneX{
//                    self.webViewNaviBar.frame = CGRect.init(x: 0,
//                                                            y: self.contentView!.safeAreaInsets.top,
//                                                            width: contentView.bounds.width,
//                                                            height: 44)
//                }else{
//                    self.webViewNaviBar.frame = CGRect.init(x: 0,
//                                                            y: 0,
//                                                            width: contentView.bounds.width,
//                                                            height: 44)
//                }
//            } else {
//                // Fallback on earlier versions
//                self.webViewNaviBar.frame = CGRect.init(x: 0,
//                                                        y: 0,
//                                                        width: contentView.bounds.width,
//                                                        height: 44)
//            }
//
//            self.openInSafariButton.frame = CGRect.init(x: self.webViewNaviBar.frame.width - 120 - 15,
//                                                        y: 5,
//                                                        width: 120,
//                                                        height: 34)
//
//            self.myWebView.frame = CGRect.init(x: contentView.frame.origin.x,
//                                               y: contentView.frame.origin.y,
//                                               width: contentView.frame.width,
//                                               height: contentView.frame.height)
//        }
//        (self.controlView as? TIGPlayerDelegate)?.player(self, orientationDidChange: deviceInfo.orientation)
    }
}

// MARK: - KVO
extension TIGPlayer {
    
    /// AVPlayerItemに登録したkeyの変化を監視
    ///
    /// - Parameters:
    ///   - keyPath: keyPath
    ///   - object: AVPlayerItem
    ///   - change: change
    ///   - context: context
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let item = object as? AVPlayerItem, let keyPath = keyPath {
            if item == self.playerItem {
                switch keyPath {
                case "status":
                    print("AVPlayerItem's status is changed: \(item.status)")
                    if item.status == .readyToPlay {
                        if self.state != .playing{
                            self.state = .readyToPlay
                        }
                    } else if item.status == .failed {
                        self.state = .error(.playerFail)
                    }

                case "loadedTimeRanges":
                    print("AVPlayerItem's loadedTimeRanges is changed")
                    (self.controlView as? TIGPlayerDelegate)?.player(self, bufferDurationDidChange: item.bufferDuration ?? 0, totalDuration: self.duration ?? 0)
                case "playbackBufferEmpty":
                    print("AVPlayerItem's playbackBufferEmpty is changed")
                case "playbackLikelyToKeepUp":
                    print("AVPlayerItem's playbackLikelyToKeepUp is changed")
                    if self.state == .playing{
                        self.play()
                    }
                default:
                    break
                }
            }
        }
    }
}
