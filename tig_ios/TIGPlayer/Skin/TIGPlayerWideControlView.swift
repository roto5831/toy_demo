
//
//  TIGPlayerWideControlView.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2016/01/16.
//  Copyright © 2016年 MMizogaki. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer
import Alamofire
import SwiftyJSON
import PromiseKit

///wide mode時にTIGPlayerを制御する
/// @ACCESS_OPEN
open class TIGPlayerWideControlView: UIView{
    
    /// TIGPlayer
    weak public var player: TIGPlayer?{
        didSet{
            self.playerControlButton.player = self.player
            self.playerMenuButton.player = self.player
            self.titleLabel.player = self.player
            self.shareButton.player = self.player
            self.playerCtrBottom.player = self.player
            self.stockAreaView.player = self.player
        }
    }
    
    /// contentsIdが切り替わるたびにAnalyticsが設定される
    var contentsId: String?{
        didSet{
            if let currentContent = PersistentManager.getFirst(CurrentContent.self){
                self.tigAnalytics.config(contentsId: currentContent.groupIdent + "-" + currentContent.contentsId)
            }
        }
    }
    
    /// グラデーション
    let gradientLayer: CAGradientLayer = CAGradientLayer()
    let lightColor = UIColor.init(white: 0, alpha: 0)
    let darkColor = UIColor.init(white: 0, alpha: 0.6)
    
    /// 再生終了時に表示される共有ボタン
    var shareButton: TIGPlayerShareButton!

    /// 画面上部グラデーションビュー
    @IBOutlet weak var topGradientView: UIView!

    ///再生時間毎に変化するSlider
    @IBOutlet weak var timeSlider: UISlider!
    
    ///timeSliderはprogressView上を移動する
    @IBOutlet weak var progressView: UIProgressView!

    ///再生時間毎のプレビュー
    @IBOutlet weak var videoshotPreview: TIGPlayerVideoshotPreview!
    
    /// 再生時間を表示するラベル
    @IBOutlet weak var timeLabel: TIGPlayerTimeLabel!
    
    /// 動画タイトルラベル
    @IBOutlet weak var titleLabel: TIGPlayerTitleLabel!
    
    /// 再生、停止ボタン
    @IBOutlet weak var playerControlButton:TIGPlayerControlButton!
    
    /// メニューに戻るボタン
    @IBOutlet weak var playerMenuButton:TIGPlayerMenuButton!
    
    /// ストックエリア
    @IBOutlet weak var stockAreaView:TIGStockView!
    
    /// loading
    @IBOutlet weak var loading: TIGPlayerLoading!
    @IBOutlet weak var modeButton: TIGPlayerModeButton!
    @IBOutlet weak var playerCtrBottom: TIGPlayerControlBar!
    @IBOutlet weak var stockAreaButton: TIGStockButton!
    
    let tigNotifi = TIGNotification()
    
    /// 再生ボタンサイズ
    let playButtonSize:(width:CGFloat, height:CGFloat) = (44, 49)
    
    /// タイムラベルサイズ
    let timeLabelSize:(width:CGFloat, height:CGFloat) = (106, 30)
    
    /// stockAreaButtonサイズ
    let stockAreaButtonSize:(width:CGFloat, height:CGFloat) = (30, 30)

    /// 横向き画面時progress view、sliderのY座標
    let yPositionOfSeekBar:(progress:CGFloat, slider:CGFloat) = (5, 0)
    
    /// 上部バーy座標
    let yPositionTopBar:(iPhonexPortrait: CGFloat, normal:CGFloat) = (40, 15)
    
    /// スライダーwidth
    let siderWidthLand:CGFloat = 80
    
    /// パーツ間距離
    let distanceBetweenParts:CGFloat = 25
    
    /// パーツが周辺から離れる距離
    let edging:CGFloat = CGFloat(15)
    
    /// 現在再生時間
    var currentTime = NSDecimalNumber(string: "0.0")
    
    /// 秒数毎にTIGobjectを描画（配置）
    var renderView:TIGObjectRenderView?
    
    /// 一定間隔でupdateCurrentTimeを実行するtimer
    var timer:Timer?
    
    /// google analyticsにデータを送信する
    let tigAnalytics = TIGAnalytics()
    
    /// Sliderを触っているかどうか
    fileprivate var isProgressSliderSliding = false
    
    /// 波紋Generator
    let rippleGenerator = RippleGenerator()
    
    /// press開始時間
    var pressBeginTime:CFAbsoluteTime!
    
    /// 最後にpressした位置
    var lastTouchedCordinates:CGPoint = CGPoint.zero
    
    /// 動画サイズキャッシュ
    var videoRectCache:Dictionary<DeviceInfo.orientationType,CGRect> = [:]
    
    /// メタデータ取得ページ管理者
    let metaPageManager = MetaPageManager()
    
    /// 端末情報
    let deviceInfo = DeviceInfo()
    
    /// モード切替の有効・無効
    open var enableToggleMode = true
    
    /// Shareボタンの表示
    open var showShareButton = true{
        didSet{
            if self.shareButton != nil{
                //self.shareButton.isHidden = !showShareButton
            }
        }
    }
    
    /// Wipeの有効・無効
    open var enableWipe = true
    
    /// モードの設定
    ///
    /// - close: 0
    /// - blink: 1
    open var tigMode = 1{
        didSet{
            if initTigMode && self.modeButton != nil {
                self.setupTigMode()
            }
        }
    }
    
    var initTigMode = false
    
    /// モードのセットアップ
    private func setupTigMode() {
        if tigMode == 0 {
            self.modeButton.close(sender: nil)
        } else {
            self.modeButton.blink(sender: nil)
        }
    }
    
    /// deinitializer
    deinit {
        self.releaseTimer()
    }
    
    /// initializer from Nib
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        // ワイプビュー通知観察
        tigNotifi.observe(TIGNotification.wipe) { [unowned self] (payload: String)  in
            if let url = URL(string:payload){
                if self.enableWipe {
                    self.playerWipe()
                    self.player?.loadingURLInWeb = url
                    self.player?.myWebView.loadRequest(URLRequest(url:url))
                } else {
                    if UIApplication.shared.canOpenURL(url) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url)
                        } else {
                            UIApplication.shared.openURL(url)
                        }
                    }
                }
            }
        }
        
        // モードの設定
        ModeManager.setCloseMode(mode: self.tigMode == 0)
        ModeManager.setBlinkMode(mode: self.tigMode == 1)
        
        // 画面上部グラデーション
        self.creatTopGradient()
        
        // 共有ボタン
        self.shareButton = TIGPlayerShareButton(frame: self.frame)
        self.shareButton.display(parentViewAlpha: 1.0, replayViewhidden: true)
        self.addSubview(self.shareButton)

        // タイムスライダー高さ及びサムネイルサイズ調整
        self.timeSlider.transform = self.timeSlider.transform.scaledBy(x: 2, y: 2)
        let thumbImageNormal : UIImage = UIImage(named:"SliderThumbNormal",
                                           in: Bundle(for:TIGPlayerWideControlView.self),
                                           compatibleWith: nil)!
        let thumbImageHighlight : UIImage = UIImage(named:"SliderThumbHighlight",
                                           in: Bundle(for:TIGPlayerWideControlView.self),
                                           compatibleWith: nil)!
        
        self.timeSlider.setThumbImage(thumbImageNormal, for: .normal)
        self.timeSlider.setThumbImage(thumbImageHighlight, for: .highlighted)
        
        self.timeSlider.value = 0
        self.progressView.progress = 0
        
        self.stockAreaView.delegate = self
        
        // メタページデータ取得マネージャー
        self.metaPageManager.comp = self
        
        // レンダービュー
        self.renderView = TIGObjectRenderView(frame:self.frame)
        self.renderView?.renderingComp = self
        self.insertSubview(renderView!, at: 0)
        
        // ローディング
        self.loading.centeringIn(parentFrame: deviceInfo.bounds)
        
        // GoogleAnalytics
        self.tigAnalytics.analyticsComp = self
        self.addSubview(self.tigAnalytics)
        
        // TIGObjectAreaView補完指定
        TIGObjectAreaView.objAreaComp = self
        TIGNotification.post(TIGNotification.showBar)
        
        // ローカルストレージに保存されたModeModelを削除
        PersistentManager.delete(BlinkModeModel.self)
        PersistentManager.delete(CloseModeModel.self)
        
        // 0.1秒刻みタイマー設定
        self.timer = Timer.scheduledTimer(timeInterval:0.1,
                                          target: self,
                                          selector: #selector(updateCurrentTime),
                                          userInfo:nil,
                                          repeats: true)
        self.timer!.fire()
        
        // TIGエリア以外の範囲にタップする時、波紋が出るビュー
        self.scheduldTimer()
        self.addSubview(rippleGenerator.rippleView)
        
        // 長押しジェスチャー
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.pressView(sender:)))
        longPressGesture.minimumPressDuration = 0.0
        longPressGesture.cancelsTouchesInView = false
        longPressGesture.delegate = self
        self.addGestureRecognizer(longPressGesture)
        self.timeLabel.text = TIGPlayerUtils.formatTime(position: 0, duration: 0)
        
        // iPhone x の対応で隠す処理がありましたので、念の為ここで表示するように
        self.modeButton.isHidden = false
        self.stockAreaButton.isHidden = false
//        print(self.bounds.size)
    }
    
    /// 端末の回転等でサブビューのFrameが変更された場合、ここで調整
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.renderView?.adjustSizeToVideoLayer()
        Meta.scale = self.getComputedMetaRenderingScale()
        self.shareButton.centeringIn(parentFrame: deviceInfo.bounds)
        if let currentTime = self.getPlayerCurrentTime(){
            self.renderView?.renderTigObject(currentTime: currentTime)
        }
        
        // 上部バーyポジション調整
        self.adjustTopBar()
        
        // ボトムバーサイズ調整
        self.playerCtrBottom.adjustSizeInCurrentOrientation()
        
        // ボトムバーパーツアレンジ
        self.rebuildBottomBar()
        
        // progressView、sliderBar
        if deviceInfo.orientation == .Portrait && self.stockAreaView.keepShowing {
            UIView.animate(withDuration: 0.2, animations: { [unowned self] in
                // timeSlider、progressView
                self.progressView.frame = CGRect.init(x: self.progressView.frame.origin.x,
                                                      y: self.playerCtrBottom.frame.height/4 - self.progressView.frame.height/2,
                                                      width: self.playerCtrBottom.frame.width - self.edging * 2 - self.stockAreaView.frame.width,
                                                      height: self.progressView.frame.height)
                
                // スライダー位置調整
                self.timeSlider.frame = CGRect.init(x: self.timeSlider.frame.origin.x,
                                                    y: self.playerCtrBottom.frame.height/4 - self.timeSlider.frame.height/2,
                                                    width: self.playerCtrBottom.frame.width - self.edging * 2 - self.stockAreaView.frame.width,
                                                    height: self.timeSlider.frame.height)
            })
        }
        
        // モードボタン
        if self.stockAreaView.isHidding {
            let x = self.frame.size.width - self.modeButton.frame.size.width - TIGPlayerWideControlView.modeButtonRightMargin
            if deviceInfo.isIpohneX && self.deviceInfo.orientation == .Portrait{
                self.modeButton.frame.origin = CGPoint.init(x: x, y: self.yPositionTopBar.iPhonexPortrait)
            }else{
                self.modeButton.frame.origin = CGPoint.init(x: x, y: self.yPositionTopBar.normal)
            }
        } else {
            var w = TIGStockView.areaWidth
            if deviceInfo.isLandScape && deviceInfo.isIpohneX {
                w = TIGStockView.areaWidth + self.stockAreaView.stockListView.frame.width/2
            }
            let x = self.frame.size.width - self.modeButton.frame.size.width - TIGPlayerWideControlView.modeButtonRightMargin - w
            if deviceInfo.isIpohneX && self.deviceInfo.orientation == .Portrait{
                self.modeButton.frame.origin = CGPoint.init(x: x, y: self.yPositionTopBar.iPhonexPortrait)
            }else{
                self.modeButton.frame.origin = CGPoint.init(x: x, y: self.yPositionTopBar.normal)
            }
        }
        
        self.stockAreaButton.isHidden = false
        
        // iPhone x対応：端末横向き時、モードボタンとストックエリア表示ボタンを隠す
        if deviceInfo.isLandScape && deviceInfo.isIpohneX{
            if self.stockAreaView.isHidding == false{
                self.stockAreaButton.isHidden = true
            }
        }
    }
    
    func scheduldTimer(){
        self.timer = Timer.scheduledTimer(timeInterval:0.1,
                                          target: self,
                                          selector: #selector(updateCurrentTime),
                                          userInfo:nil,
                                          repeats: true)
        self.timer!.fire()
    }
    
    func releaseTimer(){
        self.timer?.invalidate()
        self.timer = nil
        self.currentTime = NSDecimalNumber(string: "0.0")
    }
    // 動画コンテンツIDでコンテンツメタデータを取得
    func bind(contentsId: String) {
        // 現在contentsIdを設定
        self.setValue(contentsId, forKey: "contentsId")
        if let currentContent = PersistentManager.getFirst(CurrentContent.self){
            self.bindModel(content: currentContent)
        }
    }
    
    /// サーバーからcontentsId毎のjsonデータを取得し、Swiftオブジェクトと結びつける
    /// 完了後、player再生
    /// - Parameter content: CurrentContent
    func bindModel(content: CurrentContent) {
        // then メソッドで次の処理につなげる場合、返り値はSwiftのコンパイラーがよしなに解釈してくれないので明示的に教えてあげる必要があり.
        var contentsItemParams = Dictionary<String,String>()
        contentsItemParams[Router.param.contentsId.rawValue] = content.contentsId
        
        var metaParams = Dictionary<String,String>()
        metaParams[Router.param.contentsId.rawValue] = content.contentsId
        metaParams[Router.param.page.rawValue] = "-1"
        metaParams[Router.param.time.rawValue] = "0"
        
        firstly {
            ApiClient.request(host:Router.apiHost.getURL(path: Router.path.contentsItem), params: contentsItemParams)
        }.then { value -> Promise<Any> in
            self.parseItemResponse(json: JSON(value))
            return ApiClient.request(host:Router.apiHost.getURL(path: Router.path.meta), params: metaParams)
        }.then { value -> Promise<Any> in
            return Promise { fulfill, _ in
                if let interval = JSON(value)["body"]["interval"].string{
                    if let intervalDoubleVal = Double(interval){
                        self.metaPageManager.intervel = intervalDoubleVal
                    }
                }
                self.parseMetaResponse(json: JSON(value))
                TIGLog.verbose(message: "Success")
                fulfill("This promise always get fulfilled !!")
            }
        }.then { value -> Promise<Any> in
            return Promise { fulfill, _ in
                if let player = self.player{
                    if !player.isDisplayModeWipe{
                        player.play()
                    }
                }
                TIGNotification.post(TIGNotification.play)
                fulfill("This promise always get fulfilled !!")
            }
        }.catch{ error in
            TIGLog.error(message: "PromiseKit", anyObject:error)
        }
    }
    
    /// サーバーからcontentsId毎のメタjsonデータを取得し、Swiftオブジェクトと結びつける
    ///
    /// - Parameters:
    ///   - content: content description
    ///   - page: 現在秒数のページ
    func bindMetaModel(content: CurrentContent,page:Int,path:Router.path) {
        var metaParams = Dictionary<String,String>()
        metaParams[Router.param.contentsId.rawValue] = content.contentsId
        metaParams[Router.param.page.rawValue] = "\(page)"
        metaParams[Router.param.time.rawValue] = "-1"
        
        firstly {
            return ApiClient.request(host:Router.apiHost.getURL(path: path), params: metaParams)
        }.then { value in
            return self.parseMetaResponse(json: JSON(value))
        }.then {
            self.renderView?.renderTigObject(currentTime: self.currentTime.doubleValue)
        }.catch{ error in
                TIGLog.error(message: "PromiseKit", anyObject:error)
        }
    }

    /// GET Local Json
    /// TIGPlayerExample内ローカルJsonデータを取得する
    /// コンテンツIDを渡すのみ
    /// - Parameter contentsId: コンテンツID
    func readJsonModel(contentsId: String) {
        TIGLog.info(message: contentsId)
        
        firstly {
            ApiClient.readFromLocal(path: contentsId + "-itemdata")
        }.then { value -> Promise<Any> in
            self.parseItemResponse(json: JSON(value))
            TIGLog.debug(message:"Meta-URL", anyObject: contentsId + "-meta")
            return ApiClient.readFromLocal(path: contentsId + "-meta")
        }.then { value -> Promise<Any> in
            return Promise { fulfill, _ in
                self.parseMetaResponse(json: JSON(value))
                TIGLog.verbose(message: "Success")
                fulfill("This promise always get fulfilled !!")
            }
        }.then { value -> Promise<Any> in
            return Promise { fulfill, _ in
                if let player = self.player{
                    if !player.isDisplayModeWipe{
                        player.play()
                    }
                }
                fulfill("This promise always get fulfilled !!")
            }
        }.catch{ error in
            TIGLog.error(message: "PromiseKit", anyObject:error)
        }
    }
    
    /// item jsonをパース
    ///
    /// - Parameter json: item json
    func parseItemResponse(json: JSON) {
        guard let itemList = json["body"]["contents_item"].array else{
            return
        }
        for var item in itemList {
            guard let item = item.dictionaryObject else{
                continue
            }
            if let item = Item(JSON: item){
                self.renderView?.itemList![item.itemId] = item
            }
        }
    }

    /// meta jsonをパース
    ///
    /// - Parameter json: meta json
    func parseMetaResponse(json: JSON) {
        Meta.scale = self.getComputedMetaRenderingScale()
        if let now = json["body"][Meta.period.now.rawValue].dictionary{
            self.mapping(metaJson: now)
        }
        if let next = json["body"][Meta.period.next.rawValue].dictionary{
            self.mapping(metaJson: next)
        }
    }
    
    func mapping(metaJson: [String : JSON]){
        for (second, metaDic) in metaJson {
            guard metaDic.count != 0 else{
                continue
            }
            var metaDicList: [Meta] = []
            // uid:アイテムメタデータのキーであるitem_group
            // meta:アイテムメタデータ
            for (uid, var meta) in metaDic {
                meta["uid"].stringValue = uid
                guard let meta = meta.dictionaryObject else{
                    continue
                }
                if let parsed = Meta(JSON: meta){
                    metaDicList.append(parsed)
                }
            }
            self.renderView?.metaList![second] = metaDicList
        }
    }
    
    /// 現在の時間を0.1秒更新
    func updateCurrentTime() {
        if (self.player != nil && (self.player?.isPlaying)!) {
            currentTime = currentTime.adding(NSDecimalNumber(string: "0.1"))
            renderView?.renderTigObject(currentTime: currentTime.doubleValue)

            if !initTigMode {
                initTigMode = true
                self.setupTigMode()
            }

            self.metaPageManager.toOtherPageIn(second:currentTime.doubleValue)
        }
    }

    /// itemをstock
    /// stockAreaが開いていたら閉じる
    /// - Parameter sender: stockButton
    @IBAction func stockArea(_ sender: UIButton) {
        self.stockAreaView.sliderPoint(sender: sender)
    }

    /// Time Sliderタッチ開始した
    ///
    /// - Parameter sender: Time Slider
    @IBAction func progressSliderTouchBegan(_ sender: Any) {

        guard let player = self.player else {
            return
        }
        self.player(player, progressWillChange: TimeInterval(self.timeSlider.value))
        self.touchSeekbar(ishiden: true)
    }
    
    /// Time Slider値が変化した
    ///
    /// - Parameter sender: Time Slider
    @IBAction func progressSliderValueChanged(_ sender: Any) {

        guard let player = self.player else {
            return
        }
        self.player(player, progressChanging: TimeInterval(self.timeSlider.value))
        self.touchSeekbar(ishiden: false)
    }
    
    /// Time Sliderタッチ終了した
    ///
    /// - Parameter sender: Time Slider
    @IBAction func progressSliderTouchEnd(_ sender: Any) {

        guard let player = self.player else {
            return
        }
        self.player(player, progressDidChange: TimeInterval(self.timeSlider.value))
        self.touchSeekbar(ishiden:true)
    }

    
    
    /// videoshotPreviewにtouchSeekbarメソッドの処理を委譲
    ///
    /// - Parameter ishiden: videoshotPreview表示、非表示
    public func touchSeekbar(ishiden:Bool) {
        guard let player = self.player else {
            return
        }
        self.videoshotPreview.touchSeekbar(isHidden: ishiden, timeSlider: self.timeSlider, player: player)
    }

    /// Wipe modeに変更
    private func playerWipe() {

        guard let player = self.player else {
            return
        }
        player.toWipe()
        player.stop()
        guard
            let renderView = self.renderView,
            let metaList = renderView.metaList,
            metaList.count == 0
        else{
            return
        }
        renderView.adjustSizeToVideoLayer()
        if let contentsId = player.contentsId{
            self.bind(contentsId: contentsId)
            
        }
    }
    
    /// 上部バーの位置を下に下げる
    func adjustTopBar(){
        // iPhone x & 端末縦向き
        let deviceID = self.deviceInfo.deviceID
        NSLog("端末タイプ:\(deviceID)")
        if self.deviceInfo.isIpohneX && deviceInfo.orientation == .Portrait{
            self.playerMenuButton.frame.origin = CGPoint.init(x: self.playerMenuButton.frame.origin.x, y: self.yPositionTopBar.iPhonexPortrait)
            self.titleLabel.frame.origin = CGPoint.init(x: self.titleLabel.frame.origin.x, y: self.yPositionTopBar.iPhonexPortrait)
            self.modeButton.frame.origin = CGPoint.init(x: self.modeButton.frame.origin.x, y: self.yPositionTopBar.iPhonexPortrait)
        }else{
            self.playerMenuButton.frame.origin = CGPoint.init(x: self.playerMenuButton.frame.origin.x, y: self.yPositionTopBar.normal)
            self.titleLabel.frame.origin = CGPoint.init(x: self.titleLabel.frame.origin.x, y: self.yPositionTopBar.normal)
            self.modeButton.frame.origin = CGPoint.init(x: self.modeButton.frame.origin.x, y: self.yPositionTopBar.normal)
        }
    }
    
    /// 端末回転時bottombar再描画
    func rebuildBottomBar(){
        if deviceInfo.isLandScape{
            // 一段表示に調整
            // メニューボタン位置調整
            self.playerControlButton.frame = CGRect.init(x: self.edging,
                                                         y: self.playerCtrBottom.frame.size.height/2 - self.playerControlButton.frame.size.height/2,
                                                         width: self.playButtonSize.width,
                                                         height:self.playButtonSize.height)

            // 各パーツの間のスペースを計算する
            let spaceWidth = self.edging * 2 + self.distanceBetweenParts * 3
            
            // スライダーとプログレスビュー以外各パーツの総長さ
            let partsWidth = self.playButtonSize.width + self.timeLabelSize.width + self.stockAreaButtonSize.width
            
            // プログレスビュー位置調整
            self.progressView.frame = CGRect.init(x: self.playerControlButton.frame.origin.x + self.playerControlButton.frame.width + self.distanceBetweenParts,
                                                  y: yPositionOfSeekBar.progress,
                                                  width: self.playerCtrBottom.frame.width - spaceWidth - partsWidth,
                                                  height: self.progressView.frame.height)

            // スライダー位置調整
            self.timeSlider.frame = CGRect.init(x: self.progressView.frame.origin.x,
                                                y: yPositionOfSeekBar.slider,
                                                width: self.playerCtrBottom.frame.width - spaceWidth - partsWidth,
                                                height: self.timeSlider.frame.height)

            // タイムラベル位置調整
            self.timeLabel.frame = CGRect.init(x: self.timeSlider.frame.origin.x + self.timeSlider.frame.width + self.distanceBetweenParts,
                                               y: 0,
                                               width:self.timeLabelSize.width,
                                               height:self.timeLabelSize.height)
        }else{
            // 二段表示に調整
            // 上段
            // プログレスビュー位置再調整d
            self.progressView.frame = CGRect.init(x: self.edging,
                                                  y: self.playerCtrBottom.frame.height/4 - self.progressView.frame.height/2,
                                                  width: self.playerCtrBottom.frame.width - self.edging * 2,
                                                  height: self.progressView.frame.size.height)

            // スライダー位置再調整
            self.timeSlider.frame = CGRect.init(x: self.edging,
                                                y: self.playerCtrBottom.frame.height/4 - self.timeSlider.frame.height/2,
                                                width: self.progressView.frame.size.width,
                                                height: self.timeSlider.frame.size.height)

            NSLog("progressView: width = %f, height = %f", self.progressView.frame.size.width, self.progressView.frame.size.height)

            // 下段
            // 再生ボタン位置調整
            self.playerControlButton.frame = CGRect.init(x: self.edging,
                                                         y: self.playerCtrBottom.frame.height/2 + (self.playerCtrBottom.frame.height/2 - self.playerControlButton.frame.height)/2,
                                                         width: self.playButtonSize.width,
                                                         height: self.playButtonSize.height)
            
            // タイムラベル位置調整
            self.timeLabel.frame = CGRect.init(x: self.edging + self.playButtonSize.width + self.distanceBetweenParts,
                                               y: self.playerCtrBottom.frame.height/2 + (self.playerCtrBottom.frame.height/2 - self.timeLabel.frame.height)/2,
                                               width:self.timeLabelSize.width,
                                               height:self.timeLabelSize.height)
        }
        
        //ビデオショットプレビューの位置調整
        self.videoshotPreview.adjustOrigionYAbove(frame: self.playerCtrBottom.frame)
    }
    
    /// pressした際に波紋を表示、tapが発生したことをTIGAnalyticsに通知
    /// 一定の時間以下プレスした場合は下部のメニューバーを表示
    ///
    /// - Parameter sender: sender description
    func pressView(sender: UILongPressGestureRecognizer) {
        guard let renderView = self.renderView else{
            return
        }
        
        let touchedCordinates = sender.location(in: self)
        if let touchedView = self.hitTest(touchedCordinates, with: nil){
            if touchedView is TIGPlayerWideControlView
                || touchedView is TIGObjectRenderView{
            }else{
                return
            }
        }
        switch sender.state {
        case .began:
            self.pressBeginTime = CFAbsoluteTimeGetCurrent()
            self.lastTouchedCordinates = touchedCordinates
        case .ended:
            // 上下バー表示
            TIGNotification.post(TIGNotification.showBar)
            if let _ = self.pressBeginTime{
            }else{
                self.pressBeginTime = CFAbsoluteTimeGetCurrent()
            }
            
            let end = CFAbsoluteTimeGetCurrent()
            let second = end - self.pressBeginTime
            if second > TIGObjectRenderView.tooLongPressToShowBar{
                self.rippleGenerator.generateWhenNoHits(objectViewListInSecond: renderView.objectViewList,
                                                        coordinates: sender.location(in: self),
                                                        showBar: false,
                                                        mvRect: self.getRectAdjustedToVideo())
            }else{
                self.rippleGenerator.generateWhenNoHits(objectViewListInSecond: renderView.objectViewList,
                                                        coordinates: sender.location(in: self),
                                                        showBar: true,
                                                        mvRect: self.getRectAdjustedToVideo())
            }
        default:
            break
        }
    }
}


// MARK: - TIGPlayerCustom　Custom自体は複数の規約で成り立つ
extension TIGPlayerWideControlView: TIGPlayerCustom {

    /// Time Sliderタッチ開始した際にProgressSliderがSlidingしているとみなす
    ///
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - value: timeSlider.value
    public func player(_ player: TIGPlayer, progressWillChange value: TimeInterval) {
        if player.isLive ?? true{
            return
        }
        self.isProgressSliderSliding = true
    }
    
    /// Time Sliderが変化した際にSliderの時間と時間のラベルを変更
    ///
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - value: timeSlider.value
    public func player(_ player: TIGPlayer, progressChanging value: TimeInterval) {
        if player.isLive ?? true{
            return
        }
        self.timeLabel.text = TIGPlayerUtils.formatTime(position: value, duration: self.player?.duration ?? 0)
        if !self.timeSlider.isTracking {

            self.timeSlider.value = Float(value)
        }
    }
    
    
    /// Time Sliderのタッチが終了した際にcurrentTimeを更新しTIGPlayerの時間を更新かつProgressSliderのSlidingが終了したとみなす
    ///
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - value: timeSlider.value
    public func player(_ player: TIGPlayer, progressDidChange value: TimeInterval) {
        if player.isLive ?? true{
            return
        }
        self.currentTime = NSDecimalNumber(string: String(self.timeSlider.value))
        
        self.player?.seek(to: value, completionHandler: {
            (isFinished) in
            self.isProgressSliderSliding = false
        })
        if didProgressGetToEnd(slider: self.timeSlider){
            player.stop()
        }
    }

    
    /// Time Sliderが最後に到達したかどうか
    ///
    /// - Parameter slider: slider
    /// - Returns: maximumProgress == currentProgress
    public func didProgressGetToEnd(slider:UISlider) ->Bool{
        let maximumProgress = NSDecimalNumber(string: String(round(slider.maximumValue)))
        let currentProgress = NSDecimalNumber(string: String(round(slider.value)))
        return maximumProgress == currentProgress
    }


    /// playerのDisplayModeが変化した際に呼ばれる　現状は何もしていない
    ///
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - displayMode: TIGPlayer.TIGPlayerDisplayMode
    public func player(_ player: TIGPlayer, playerDisplayModeDidChange displayMode: TIGPlayer.TIGPlayerDisplayMode) {

        switch displayMode {
        case .None:
            break
        case .Wide:
            break
        case .Wipe:
            break
        }
    }

    
    /// playerの状態が変化した際に呼ばれる
    ///
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - state: TIGPlayer.TIGPlayerState
    public func player(_ player: TIGPlayer, playerStateDidChange state: TIGPlayer.TIGPlayerState) {
        TIGLog.debug(message: "TIGPlayerDelegate:playerStateDidChange", anyObject: "state:\(state)")
        switch state {
        case .error:
            player.playbackDidFinish(reason: .playbackError)
            self.player(player, showLoading: false)
        case .readyToPlay:
            switch player.previousState {
            case .unknown:
                self.renderView?.adjustSizeToVideoLayer()
                if let contentsId = player.contentsId{
                    self.bind(contentsId: contentsId)
                }
                self.playerControlButton.setBackGroundToStop()
            case .pause:
                self.playerControlButton.setBackGroundToPlay()
                player.pause()
            default:
                if !self.didProgressGetToEnd(slider: self.timeSlider){
                    self.playerControlButton.setBackGroundToStop()
                    player.play()
                }
            }
        case .stopped:
            TIGNotification.post(TIGNotification.stop)
            if deviceInfo.orientation == .Portrait {
                UIView.animate(withDuration: 0.2, animations: { [unowned self] in
                    // timeSlider、progressView
                    self.progressView.frame = CGRect.init(x: self.progressView.frame.origin.x,
                                                          y: self.playerCtrBottom.frame.height/4 - self.progressView.frame.height/2,
                                                          width: self.playerCtrBottom.frame.width - self.edging * 2 - self.stockAreaView.frame.width,
                                                          height: self.progressView.frame.height)
                    // スライダー位置調整
                    self.timeSlider.frame = CGRect.init(x: self.timeSlider.frame.origin.x,
                                                        y: self.playerCtrBottom.frame.height/4 - self.timeSlider.frame.height/2,
                                                        width: self.playerCtrBottom.frame.width - self.edging * 2 - self.stockAreaView.frame.width,
                                                        height: self.timeSlider.frame.height)
                    
                })
            }
            self.stockAreaView.sliderPoint(sender: self.stockAreaButton)
            self.playerControlButton.setBackGroundToReplay()
            //self.shareButton.display(parentViewAlpha: 0.8, replayViewhidden: !self.showShareButton)
//            self.shareButton.display(parentViewAlpha: 0.8, replayViewhidden: false)
            self.player(player, showLoading: false)
        case .pause:
            TIGNotification.post(TIGNotification.stop)
//            self.shareButton.display(parentViewAlpha: 1.0, replayViewhidden: true)
            self.player(player, showLoading: false)
            self.renderView?.renderTigObject(currentTime: self.currentTime.doubleValue)
            self.metaPageManager.toOtherPageIn(second:self.currentTime.doubleValue)
        case .playing:
            self.stockAreaView.closeStockArea(self.stockAreaButton)
//            self.shareButton.display(parentViewAlpha: 1.0, replayViewhidden: true)
            self.player(player, showLoading: false)
        default:
//            self.shareButton.display(parentViewAlpha: 1.0, replayViewhidden: true)
            self.player(player, showLoading: true)
        }
    }

    
    /// playerのbufferDurationが変化した際に呼ばれる。progressViewの値を変更する
    ///
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - bufferDuration: bufferDuration
    ///   - totalDuration: totalDuration
    public func player(_ player: TIGPlayer, bufferDurationDidChange bufferDuration: TimeInterval, totalDuration: TimeInterval) {
        if totalDuration.isNaN || bufferDuration.isNaN || totalDuration == 0 || bufferDuration == 0{
            self.progressView.progress = 0
        }else{
            self.progressView.progress = Float(bufferDuration/totalDuration)
        }
    }

    
    /// playerのcurrentTimeが0.1毎に更新され、その際に呼ばれる。timeSliderの値とplayerの時間の同期を取る
    ///
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - currentTime: currentTime
    ///   - duration: duration
    public func player(_ player: TIGPlayer, currentTime: TimeInterval, duration: TimeInterval) {
        if currentTime.isNaN || (currentTime == 0 && duration.isNaN){
            return
        }

        self.timeSlider.isEnabled = !duration.isNaN
        self.timeSlider.minimumValue = 0
        self.timeSlider.maximumValue = duration.isNaN ? Float(currentTime) : Float(duration)
        if !self.isProgressSliderSliding {

            self.timeSlider.value = Float(currentTime)
            self.timeLabel.text = duration.isNaN ? "Live" : TIGPlayerUtils.formatTime(position: currentTime, duration: duration)
            self.touchSeekbar(ishiden: true)
        }
    }

    
    /// loading表示
    ///
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - showLoading: showLoading
    public func player(_ player: TIGPlayer ,showLoading: Bool){
        if showLoading {
            self.loading.start()
        }else{
            self.loading.stop()
        }
    }
    
    /// 端末の方向が変化
    /// setNeedsLayoutでlayoutSubviewsを呼び出すためのマーキング
    /// - Parameters:
    ///   - player: player
    ///   - orientationType: DeviceInfo.orientationType
    public func player(_ player: TIGPlayer ,orientationDidChange orientationType: DeviceInfo.orientationType){
        self.setNeedsLayout()
    }
    
    /// 画面上部グラデーションクリエイト
    public func creatTopGradient(){
        let deviceWidth =  deviceInfo.bounds.width > deviceInfo.bounds.height ? deviceInfo.bounds.width:deviceInfo.bounds.height
        
        // グラデーションビュー横幅調整
        self.topGradientView.frame = CGRect.init(origin: CGPoint.zero,
                                                 size: CGSize.init(width: deviceWidth, height: self.topGradientView.frame.height))
        
        //画面Topグラデーション
        gradientLayer.colors = [darkColor.cgColor, lightColor.cgColor]
        gradientLayer.frame = self.topGradientView.bounds
        self.topGradientView.layer.insertSublayer(gradientLayer, at: 0)
    }
}


// MARK: - TIGObject描画に関して補完
extension TIGPlayerWideControlView:TIGObjectRenderingComplement{
    
    /// 動画データそのものの幅と高さとデバイス上の動画サイズの幅と高さからTIGObject描画座標計算に使用するscaleを取得
    /// メタデータの座標は動画データそのものの幅と高さを前提としているので、描画する際にデバイス上の動画サイズとの比率を考慮して描画座標計算する必要がある
    ///
    /// - Returns: (computedXpointScale,computedYpointScale)
    func getComputedMetaRenderingScale() -> (x:CGFloat,y:CGFloat) {
        if let player = self.player{
            let presentationSize = player.getPresentationVideoSize()
            let rect = self.getRectAdjustedToVideo()
            let computedXpointScale = rect.width / presentationSize.width
            let computedYpointScale = rect.height / presentationSize.height
            return (computedXpointScale,computedYpointScale)
        }
        return (0,0)
    }
    
    /// 動画自体の縦横比率とデバイスの縦横縦横比率があっていない場合、動画比率に合わせた描画領域を取得
    ///
    /// - Returns: CGRect
    func getRectAdjustedToVideo() -> CGRect{
        if !self.videoRectCache.isEmpty{
            if let cachedRect = self.videoRectCache[deviceInfo.orientation]{
                return cachedRect
            }else{
                return self.getVideRectSize()
            }
        }
        return self.getVideRectSize()
    }
    
    func getVideRectSize() -> CGRect{
        if let videoRect = self.player?.getVideoRectangle(){
            let size = CGRect(x:(deviceInfo.rawSize.width - videoRect.width)/2,
                              y:(deviceInfo.rawSize.height - videoRect.height)/2,
                              width: (videoRect.width / deviceInfo.rawSize.width) * deviceInfo.rawSize.width,
                              height: (videoRect.height / deviceInfo.rawSize.height) * deviceInfo.rawSize.height)
            if size.width != 0{
                self.videoRectCache[deviceInfo.orientation] = size
            }
            return size
        }
        return self.bounds
    }
    
    /// ProgressSliderがまだ動いているかどうか
    ///
    /// - Returns: isProgressSliderSliding
    func isProgressSliderStillSliding() -> Bool{
        return self.isProgressSliderSliding
    }
    
    /// playerの現在時刻を取得
    ///
    /// - Returns: currentTime
    func getPlayerCurrentTime() -> TimeInterval?{
        return self.player?.currentTime
    }
    
    
    /// playerの現在状態を取得
    ///
    /// - Returns: TIGPlayer.TIGPlayerState
    func getPlayerCurrentState() -> TIGPlayer.TIGPlayerState?{
        return self.player?.state
    }
}

// MARK: - TIGPlayerAnalytics補完
extension TIGPlayerWideControlView:TIGAnalyticsComplement, TIGObjectAreaComplement {

    /// 現在時間を取得
    ///
    /// - Returns: currentTime
    public func getCurrentTime()->NSDecimalNumber{
        return self.currentTime
    }
    
    /// TIGPlayerを取得
    ///
    /// - Returns: player
    public func getPlayer()->TIGPlayer?{
        return self.player
    }
    
    /// GAに送るtap pointの値を計算するため、動画比率に合わせた描画領域を取得する
    func getAdjustedVideoRect() -> CGRect{
        return self.getRectAdjustedToVideo()
    }
}

// MARK: - gesture同時認識(子ビューも含めて)StockViewのスクロールが殺されてしまう
extension TIGPlayerWideControlView:UIGestureRecognizerDelegate{
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

// MARK: - MetaPageManagerComplement

extension TIGPlayerWideControlView:MetaPageManagerComplement{
    
    /// 現在秒数でのページが変更された
    ///
    /// - Parameter newPage:
    func pageDidChange(newPage:Int){
        print("newPage:\(newPage)")
        if let currentContent = PersistentManager.getFirst(CurrentContent.self){
            self.bindMetaModel(content: currentContent, page: newPage,path:Router.path.meta)
        }
    }
}

// MARK: - TIGPlayerControlButtonComplement
extension TIGPlayerWideControlView:TIGPlayerControlButtonComplement{
    
    /// Replay
    func didReplay() {
        self.releaseTimer()
        self.scheduldTimer()
    }
}

// MARK: - TIGStockViewDelegate
extension TIGPlayerWideControlView:TIGStockViewDelegate{
    /// 表示時
    func showStockView() {
        // モードボタンの位置
        UIView.animate(withDuration: 0.2, animations: { [unowned self] in
            let deviceID = self.deviceInfo.deviceID
            var w = TIGStockView.areaWidth
            if self.deviceInfo.isLandScape && self.deviceInfo.isIpohneX {
                w = TIGStockView.areaWidth + self.stockAreaView.stockListView.frame.width/2
            }
            let x = self.frame.size.width - self.modeButton.frame.size.width - TIGPlayerWideControlView.modeButtonRightMargin - w
            
            if self.deviceInfo.isIpohneX && self.deviceInfo.orientation == .Portrait{
                self.modeButton.frame.origin = CGPoint.init(x: x, y: self.yPositionTopBar.iPhonexPortrait)
            }else{
                self.modeButton.frame.origin = CGPoint.init(x: x, y: self.yPositionTopBar.normal)
            }
        })
        
        // 縦向き時
        if deviceInfo.orientation == .Portrait {
            UIView.animate(withDuration: 0.2, animations: { [unowned self] in
                // timeSlider、progressView
                self.progressView.frame = CGRect.init(x: self.progressView.frame.origin.x,
                                                      y: self.playerCtrBottom.frame.height/4 - self.progressView.frame.height/2,
                                                      width: self.playerCtrBottom.frame.width - self.edging * 2 - self.stockAreaView.frame.width,
                                                      height: self.progressView.frame.height)
                // スライダー位置調整
                self.timeSlider.frame = CGRect.init(x: self.timeSlider.frame.origin.x,
                                                    y: self.playerCtrBottom.frame.height/4 - self.timeSlider.frame.height/2,
                                                    width: self.playerCtrBottom.frame.width - self.edging * 2 - self.stockAreaView.frame.width,
                                                    height: self.timeSlider.frame.height)
                
            })
        }
    }
    
    /// 非表示時
    func hideStockView() {
        // モードボタンの位置
        UIView.animate(withDuration: 0.2, animations: { [unowned self] in
            let deviceID = self.deviceInfo.deviceID
            let x = self.frame.size.width - self.modeButton.frame.size.width - TIGPlayerWideControlView.modeButtonRightMargin
            if self.deviceInfo.isIpohneX && self.deviceInfo.orientation == .Portrait{
                self.modeButton.frame.origin = CGPoint.init(x: x, y: self.yPositionTopBar.iPhonexPortrait)
            }else{
                self.modeButton.frame.origin = CGPoint.init(x: x, y: self.yPositionTopBar.normal)
            }
        })
        
        // 縦向き時
        if self.deviceInfo.orientation == .Portrait {
            UIView.animate(withDuration: 0.2, animations: { [unowned self] in
                // timeSlider、progressView
                self.progressView.frame = CGRect.init(x: self.progressView.frame.origin.x,
                                                      y: self.progressView.frame.origin.y,
                                                      width: self.playerCtrBottom.frame.width - self.edging * 2,
                                                      height: self.progressView.frame.height)
                
                // スライダー位置調整
                self.timeSlider.frame = CGRect.init(x: self.timeSlider.frame.origin.x,
                                                    y: self.timeSlider.frame.origin.y,
                                                    width: self.playerCtrBottom.frame.width - self.edging * 2,
                                                    height: self.timeSlider.frame.height)
                }, completion: { _ in
                    
            })
        }
    }
}

