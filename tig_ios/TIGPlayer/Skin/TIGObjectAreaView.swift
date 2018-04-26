//
//  TIGObjectAreaView.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/04/07.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

/// TIGObjectAreaView補完
protocol TIGObjectAreaComplement:class{
    /// 現在の再生時間がデータ送信時に必要
    ///
    /// - Returns: CurrentTime
    func getCurrentTime()->NSDecimalNumber
    
    /// TIGPlayerを取得
    ///
    /// - Returns: player
    func getPlayer()->TIGPlayer?
    
    /// GAに送るtap pointの値を計算するため、動画比率に合わせた描画領域を取得する
    func getAdjustedVideoRect() -> CGRect
}

/// mode切替時のTIGObjectの切替やgestureイベントを制御
class TIGObjectAreaView: TIGObjectImage,UIGestureRecognizerDelegate {
    
    /// drag(pan)の状態
    var viewDragState: dragState = .noDragging
    
    /// swipの状態
    var viewSwipState: swipState = .noSwiping
    
    /// TIG時のTIGobject
    var objectOpen: TIGObjectView! = TIGObjectView()
    
    /// blink mode時のTIGobject
    var objectMark:TIGObjectMarkView?
    
    /// open mode時のTIGobject用item
    var item: Item?{
        didSet{
            self.objectOpen.thumb.setImageViewWeb(urlString: (item?.itemThumbnailURL)!)
            self.objectOpen.label.text = item?.itemTitle
            self.objectMark?.labelText = (item?.itemTitle)!
        }
    }
    
    /// TIGNotification
    let tigNotification = TIGNotification()
    
    ///blinkモード時にモードは切り替えずに表示上closeと同じ状態にする
    var blinkTimer: Timer?
    
    /// 同一秒数で重複したアイテムかどうか
    var duplicateFlg:Bool?
    
    /// タッチしている状態かどうか
    var touching:Bool = false{
        didSet{
            self.objectOpen.touching = touching
        }
    }
    
    /// TIGPlayerWideControlViewインスタンス
    weak var wideControlView :TIGPlayerWideControlView?
    
    /// TIGPlayer
    weak var player: TIGPlayer?{
        didSet{
            self.wideControlView = self.player?.controlView as? TIGPlayerWideControlView
        }
    }
    
    /// playerの状態
    var playerState:TIGPlayer.TIGPlayerState?{
        willSet(newState){
            if let newState = newState{
                switch newState{
                case .pause:
                    self.changeViewAppearance()
                default:
                    break
                }
            }
        }
    }
    
    // Blinkを表示中か？
    public func activeBlink() -> Bool {
        return touching || !((objectMark?.isHidden)!)
    }
    
    /// RippleGeneratorで波紋を生成するかどうかのhitTestに使用
    var hit:Bool = false
    
    /// TIGObject描画用のview
    var renderView:TIGObjectRenderView?
    
    /// 20180216修正：TIG位置を保存
    var tigCoordinates: CGPoint?
    
    /// google analyticsにデータを送信する
    //let tigAnalytics = TIGAnalytics()
  
    /// TIGObjectAreaView補完
    static weak var objAreaComp:TIGObjectAreaComplement?
    
    /// サムネイルを右へ移動する前の座標
    var previousCordinateBeforePan:CGPoint?
    
    /// キャンセル用のワーカーアイテム
    var tapEndedWorkItem:DispatchWorkItem?
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true

        objectMark = TIGObjectMarkView.init(frame:CGRect(x:0,
                                                         y:0,
                                                         width: TIGObjectMarkView.baseSize.width,
                                                         height: TIGObjectMarkView.baseSize.height))
        objectMark?.isHidden = ModeManager.getBlinkMode()
        self.addSubview(objectMark!)

        objectOpen.isHidden = true
        self.addSubview(objectOpen)
        
        self.renderView = self.getRenderView()
        
        // pan
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panView(sender:)))
        panGesture.delegate = self
        self.addGestureRecognizer(panGesture)
     
        // 長押し
        let tapGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.tapView(sender:)))
        tapGesture.delegate = self
        tapGesture.allowableMovement = TIGObjectAreaView.tapArea
        tapGesture.minimumPressDuration = TIGObjectAreaView.pressDuration
        self.addGestureRecognizer(tapGesture)
        
        tigNotification.observe(TIGNotification.markClose) {_ in
            self.invalidateTimers()
            self.closeMode()
        }

        tigNotification.observe(TIGNotification.markBlink) {(payload: String) in
            self.invalidateTimers()
            self.blinkMode(interval: TimeInterval(payload)!)
            self.makeDuplicateClosed()
        }
        
        // tig item
        tigNotification.observe(TIGNotification.tigAnimaStop) {_ in
            self.objectOpen.isHidden = true
            self.objectOpen.circle.removeAllAnimations()
            self.objectOpen.circle.removeFromSuperlayer()
            self.tigItem()
            if self.objectOpen.finished {
                self.objectMark?.isHidden = true
            }
        }
    }
    
    /// サイズが変更されたときに、吹き出しの位置を調整する
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.objectMark?.calcFrame()
    }

    /// 重複アイテムを表示しない
    func makeDuplicateClosed(){
        if let duplicateFlg = duplicateFlg{
            if duplicateFlg{
                self.viewCloseMode(nil,duration:0.0)
            }
        }
    }
    
    /// timer無効化
    func invalidateTimers() {
            self.blinkTimer?.invalidate()
    }

    /// timerをクリア
    func clearTimers() {
        self.blinkTimer = nil
    }

    /// modeは変更せずに外観だけ変更
    func changeViewAppearance(){
        if ModeManager.getCloseMode() {
            self.viewCloseMode()
        } else if ModeManager.getBlinkMode(){
            self.viewBlinkMode(interval: 0)
        }
    }
    
    /// modeをcloseにする
    func closeMode() {
        self.viewCloseMode(nil, duration: 0.01)
        ModeManager.setCloseMode(mode:true)
        ModeManager.setBlinkMode(mode: false)
    }
    
    /// mode変更せずに表示しない状態にする
    func viewCloseMode(_ timer: Timer? = nil) {
        viewCloseMode(timer, duration: 0.0)
    }
    
    /// mode変更せずに表示しない状態にする
    /// タッチしている時は常に表示
    /// playerの状態がpauseでかつclose mode以外で重複アイテムでない時は常に表示
    func viewCloseMode(_ timer: Timer? = nil,duration:Double){
        guard !touching else{
            return
        }

        if let userInfo = timer?.userInfo as? Dictionary<String, Any>{
            if userInfo["seeked"] as! Bool{
                self.objectMark?.isHidden = true
                self.objectOpen?.isHidden = true
                return
            }
        }

        if let playerState = self.playerState{
            if playerState == .pause && !ModeManager.getCloseMode(){
                if let duplicateFlg = self.duplicateFlg{
                    if !duplicateFlg{
                        self.objectOpen.thumb.isHidden = false
                        return
                    }
                }
            }
        }
        
        self.fadeOutAnimatinon(duration: 0.0, withMark: true)
    }
    
    /// フェードアウトアニメーション
    func fadeOutAnimatinon(duration:Double, withMark:Bool) {
        if withMark {
            UIView.animate(withDuration: duration, delay: 0.0, options:[.allowUserInteraction], animations: {
                () -> Void in
                self.objectMark?.alpha = 0
            }, completion: {(_ finished: Bool) -> Void in
                self.objectMark?.isHidden = true
                self.objectMark?.alpha = 1
            })
        }
        
        self.objectOpen.fadeOutAnimatinon(duration: duration)
    }
    
    /// modeをblinkにする
    func blinkMode(interval: TimeInterval) {
        self.viewBlinkMode(interval:interval)

        ModeManager.setCloseMode(mode:false)
        ModeManager.setBlinkMode(mode: true)
    }
    
    /// blink modeのまま表示しない状態にする
    func viewBlinkMode(interval:TimeInterval) {
        objectMark?.isHidden = false
        objectOpen?.isHidden = true
    }
    
    /// TIGobjectを移動させる
    ///
    /// - Parameter sender: UIPanGestureRecognizer
    func panView(sender: UIPanGestureRecognizer) {
        let moveX:CGFloat = sender.translation(in: self).x
        let speedX:CGFloat = sender.velocity(in: self).x
        // Main Threadで実行する
        self.frame.origin.x = sender.translation(in: self).x
        self.frame.origin.y = sender.translation(in: self).y

        switch sender.state {
        case .began:
            self.resetObjectAlphaAndAnimation()
            self.touching = true
            self.viewDragState = .dragging
            self.objectOpen.isHidden = false
            self.objectMark?.isHidden = true
            // 2018.2.19:プロトタイプTIG動作に矢印を表示しません
//            TIGNotification.post(TIGNotification.dispArrow)
            self.previousCordinateBeforePan = self.layer.position
            break
        case .changed:
            self.viewDragState = .dragging
            self.objectOpen.isHidden = false
            // 2018.2.19:プロトタイプTIG動作に矢印を表示しません
//            TIGNotification.post(TIGNotification.dispArrow)
            break
        case .cancelled:
            self.touching = false
            self.objectOpen.isHidden = true
            // 2018.2.19:プロトタイプTIG動作に矢印を表示しません
//            TIGNotification.post(TIGNotification.hideArrow)
            self.previousCordinateBeforePan = nil
            break
        case .ended:
            self.touching = false
            self.viewDragState = .noDragging
            self.objectOpen.isHidden = true
            // 2018.2.19:プロトタイプTIG動作に矢印を表示しません
//            TIGNotification.post(TIGNotification.hideArrow)
            self.viewCloseMode(nil,duration:0.0)
            if let previousCordinateBeforePan = self.previousCordinateBeforePan{
                self.layer.position = previousCordinateBeforePan
            }
            let playerView = TIGObjectAreaView.objAreaComp?.getPlayer()?.computedPlayerView
            self.tigCoordinates = sender.location(in: playerView)
            self.tigItem(move: moveX, speed: speedX)
            self.tigCoordinates = nil
            break
        default:
            break
        }
    }

    /// アルファ値とアニメーションのリセット
    private func resetObjectAlphaAndAnimation() {
        self.tapEndedWorkItem?.perform()
        self.tapEndedWorkItem?.cancel()
        self.layer.removeAllAnimations()
        self.objectMark?.layer.removeAllAnimations()
        self.objectOpen?.layer.removeAllAnimations()
        self.objectOpen.thumb.layer.removeAllAnimations()
        self.objectMark?.alpha = 1
        self.objectOpen?.alpha = 1
        self.objectOpen.thumb.alpha = 1
    }
    
    /// TIGobjectをタップ
    ///　タップした際のAnalyticsへの通知はRippleGeneratorに記述 ※areaViewの範囲外をtapした際にも送信する必要があるため
    /// - Parameter sender: UILongPressGestureRecognizer
    func tapView(sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            self.resetObjectAlphaAndAnimation()
            self.touching = true
            let tappedCordinate = sender.location(in: self)
            self.objectOpen.tappedCordinate = tappedCordinate
            let playerView = TIGObjectAreaView.objAreaComp?.getPlayer()?.computedPlayerView
            self.tigCoordinates = sender.location(in: playerView)
            self.objectOpen.isHidden = false
            self.hit = true
            self.objectOpen.drawCircle()
            break
        case .cancelled:
            self.touching = false
            self.objectOpen.tappedCordinate = nil
            self.tigCoordinates = nil
            self.objectOpen.isHidden = true
            // 2018.2.19:プロトタイプTIG動作に矢印を表示しません
//            TIGNotification.post(TIGNotification.hideArrow)
            TIGNotification.post(TIGNotification.tigAnimaCancel)
            break
        case .ended:
            self.touching = false
            self.hit = false
            self.fadeOutAnimatinon(duration:0.7, withMark: false)
            TIGNotification.post(TIGNotification.tigAnimaCancel)
            
            self.tapEndedWorkItem = DispatchWorkItem() {
                self.objectOpen.tappedCordinate = nil
                self.tigCoordinates = nil
                self.viewDragState = .noDragging
                self.objectOpen.isHidden = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7, execute: tapEndedWorkItem!)
            break
        default:
            break
        }
    }
    
    /// TIGobjectをスワイプ
    /// itemをストックしてデータをローカルに永続化
    /// Analyticsにスワイプしたことを通知
    /// TIGPlayerControlTopに非表示の通知
    /// - Parameters:
    ///   - move: moveX
    ///   - speed: velocity
    ///   - sender: UIGestureRecognizer
    func tigItem(move:CGFloat? = nil, speed:CGFloat? = nil){
        if move != nil && speed != nil {
            guard speed! > 100 && move! > 10 else {
                self.tigCoordinates = nil
                return
            }
        }
        self.hit = false
        if self.item != nil && self.tigCoordinates != nil{
            if let currentContent = PersistentManager.getFirst(CurrentContent.self){
                var items:Items? = PersistentManager.getByPrimaryKey(Items.self, primaryKey: currentContent.contentsId)
                if let  _ = items{
                }else{
                    items = Items()
                }
                var itemModel:ItemModel? = PersistentManager.getByPrimaryKey(ItemModel.self, primaryKey: "\(currentContent.contentsId)\(self.item!.itemId)")
                if let  _ = itemModel{
                }else{
                    itemModel = ItemModel()
                }
                PersistentManager.update(itemModel){
                    itemModel!.itemIdInt = self.item!.itemIdInt
                    itemModel!.itemId = self.item!.itemId
                    itemModel!.contentsId = currentContent.contentsId
                    itemModel!.itemThumbnailURL = self.item!.itemThumbnailURL
                    itemModel!.itemWebURL = self.item!.itemWebURL
                    itemModel!.itemTitle = self.item!.itemTitle
                    let currentTime = TIGObjectAreaView.objAreaComp?.getCurrentTime()
                    NSLog("currentTime:%d", currentTime!)
                    itemModel!.stockTime = self.makeTimeString(currentTime!)
                    NSLog("currentTime:\(itemModel!.stockTime)")
                }
                PersistentManager.update(items){
                    /// Description
                    if items!.list.contains(itemModel!){
                        items!.remove(index: items!.indexOfKey(key: itemModel!.key))
                    }
                    items!.contentsId = currentContent.contentsId
                    items!.insert(itemModel!, index: 0)
                }
                
                // TIG位置をGAに送信
                if let item = self.item {
                    if let coordinates = self.tigCoordinates{
                        // 動画の横縦比率で調整した実際に画面上で表示している動画Rect
                        let adjustedVideoRect = TIGObjectAreaView.objAreaComp?.getAdjustedVideoRect()
                        // tap箇所が実際に画面上で表示している動画領域のどの位置にある
                        let tapPointX = (coordinates.x - (adjustedVideoRect?.origin.x)!) / (adjustedVideoRect?.width)!
                        let tapPointXRound = round(tapPointX*100000)/100000
                        print("tapPointXRound:\(tapPointXRound)")
                        let tapPointY = (coordinates.y - (adjustedVideoRect?.origin.y)!) / (adjustedVideoRect?.height)!
                        let tapPointYRound = round(tapPointY*100000)/100000
                        print("tapPointYRound:\(tapPointYRound)")
                        // GAへ送信
                        TIGNotification.post(TIGNotification.stock, from: nil, payload: [
                            "x": tapPointXRound,
                            "y": tapPointYRound,
                            "itemId": item.itemId
                            ])
                    }
                }
            }
        }
        TIGNotification.post(TIGNotification.hideTopCtr)
    }
    
    /// 同時に複数のRecognizerを認識すべきかどうか
    ///
    /// - Parameters:
    ///   - gestureRecognizer: gestureRecognizer
    ///   - otherGestureRecognizer: otherGestureRecognizer
    /// - Returns: Bool
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    
    /// RenderView取得
    /// ※今後、仕様変更でTIGObjectRenderViewからTIGObjectAreaViewの階層が変更された場合を考慮して最大10段階までさかのぼって取得
    /// - Returns: TIGObjectRenderView
    func getRenderView()->TIGObjectRenderView?{
        var targetView = self.superview
        var count = 0
        while(true){
            guard count < 10 else{
                return nil
            }
            if isRenderView(targetView: targetView){
                return targetView as? TIGObjectRenderView
            }else{
                targetView = targetView?.superview
            }
            count = count+1
        }
    }
    
    
    /// RenderViewかどうか
    ///
    /// - Parameter targetView: targetView
    /// - Returns: Bool
    func isRenderView(targetView:UIView?)->Bool{
        if let targetView = targetView{
            return targetView is TIGObjectRenderView
        }
        return false
    }
    
    /// 現在時間の秒数を文字列に変換
    ///
    /// - Parameter currentTime: NSDecimalNumber
    /// - Returns: currentTimeStr
    func makeTimeString(_ currentTime: NSDecimalNumber) -> String {
        let mCurrentTime = currentTime.doubleValue
        let secondsCurrentTime:String = String(mCurrentTime)
        return secondsCurrentTime
    }
}

