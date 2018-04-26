import UIKit

/// 波紋生成者
/// @ACCESS_OPEN
open class RippleGenerator{

    /// 波紋生成タイマー：仕様上１つしか使わない
    var timers: [Timer] = []
    
    /// 波紋view:親viewに追加してください
    let rippleView = UIView(frame: CGRect(origin: CGPoint.zero, size: CGSize.zero))

    /// initializer
    init(){
        self.rippleView.alpha = 0.2
    }
    
    /// deinitializer
    deinit{
        self.calm()
    }

    /// ObjectArea以外をタップした際に波紋生成
    /// 空振りtapのAnalyticsへのデータ送信はここで行う
    /// オプションでフッターを表示
    /// - Parameters:
    ///   - objectViewListInSecond: 現在秒のobjectViewList
    ///   - coordinates: 座標
    ///   - showBar: フッターを表示するかどうか
    func generateWhenNoHits(objectViewListInSecond: [String: TIGObjectMoveView], coordinates:CGPoint, showBar:Bool, mvRect:CGRect){
        if !self.hitTest(objectViewListInSecond: objectViewListInSecond, coordinates: coordinates, mvRect: mvRect){
            self.at(coordinates: coordinates)
            
            if showBar{
                TIGNotification.post(TIGNotification.showBar)
            }
            // tap箇所が実際に画面上で表示している動画領域のどの位置にある情報を取得する
            let tapPoint:CGPoint = self.tapPoint(coordinates: coordinates, mvRect: mvRect)
            // GAへ送信
            TIGNotification.post(TIGNotification.tap, from: nil, payload: [
                "x": tapPoint.x,
                "y": tapPoint.y,
                "itemId": "notItem"
            ])
        }
        objectViewListInSecond.forEach{view in
            if let areaView = view.value.areaView{
                areaView.hit = false
            }
        }
    }

    /// 指定した座標に波紋表示
    ///
    /// - Parameter coordinates: coordinates
    private func at(coordinates:CGPoint){
        self.ripple(coordinates,view: self.rippleView)
        self.calm()
    }

    /// オブジェクトエリアに触れていないかどうかの判定
    /// tapのAnalyticsへのデータ送信はここで行う
    /// - Parameters:
    ///   - objectViewListInSecond: 現在秒数のobjectViewList
    ///   - coordinates: 座標
    /// - Returns: hitAtleastOne
    private func hitTest(objectViewListInSecond: [String: TIGObjectMoveView], coordinates:CGPoint, mvRect:CGRect) ->Bool{
        var hitAtleastOne = false
        objectViewListInSecond.forEach{view in
            if let areaView = view.value.areaView{
                if areaView.hit{
                    if let item = areaView.item{
                        // tap箇所が実際に画面上で表示している動画領域のどの位置にある情報を取得する
                        let tapPoint:CGPoint = self.tapPoint(coordinates: coordinates, mvRect: mvRect)
                        // GAへ送信
                        TIGNotification.post(TIGNotification.tap, from: nil, payload: [
                            "x": tapPoint.x,
                            "y": tapPoint.y,
                            "itemId": item.itemId
                        ])
                    }
                    hitAtleastOne = true
                }
            }
        }
        return hitAtleastOne
    }

    /// Google Analyticsに送るタップポジション情報
    ///
    /// - Parameters:
    ///   - coordinates: タップローケーション
    ///   - mvSize: 動画サイズ（ピクセル）
    /// - Returns: タップした箇所は動画再生領域のどっちにある
    private func tapPoint(coordinates:CGPoint, mvRect:CGRect) -> CGPoint {
        // tapが動画再生のどの領域に発生したかを表す比率計算
        let tapPointX:CGFloat = (coordinates.x - mvRect.origin.x) / mvRect.width
        let tapPointXRound = round(tapPointX*100000)/100000
        print("tapPointXRound:\(tapPointXRound)")
        let tapPointY:CGFloat = (coordinates.y - mvRect.origin.y) / mvRect.height
        let tapPointYRound = round(tapPointY*100000)/100000
        print("tapPointYRound:\(tapPointYRound)")
        // 戻り値
        let tapPoint:CGPoint = CGPoint.init(x: tapPointXRound, y: tapPointYRound)
        return tapPoint
    }
    
    /**
     水の中に雫を落とすように波紋効果生成
     - Parameter center: 波紋の中心点
     - Parameter view: 波紋があらわれるビュー
     - Parameter times: (任意)波紋がリピートする回数　標準は無限
     - Parameter duration: (任意) それぞれの波紋効果の時間　標準は0.5
     - Parameter size: (任意) 波紋の初期サイズ　標準は10
     - Parameter multiplier: (任意) 終了サイズを知るのに適用される乗算子　標準は10
     - Parameter divider: (任意) タイマーが次の波紋を適用するための除算子　標準は2
     - Parameter color: (任意) 波紋の色　標準はシアン
     - Parameter border: (任意) 波紋のボータの幅　標準は2.25
     */
    public func ripple(_ center: CGPoint, view: UIView, times: Float = Float.infinity,
                       duration: TimeInterval = 0.5,
                       size: CGFloat = 10,
                       multiplier: CGFloat = 10,
                       divider: CGFloat = 2,
                       color: UIColor = UIColor.cyan,
                       border: CGFloat = 2.25) {

        let ripple = droplet(center, view: view, duration: duration,
                             size: size, multiplier: multiplier, color: color, border: border)
        let timer = Timer.scheduledTimer(timeInterval: duration / Double(divider),
                                         target: ripple,
                                         selector: #selector(Ripple.timerDidFire),
                                         userInfo: nil, repeats: true)

        timers.append(timer)

        guard times != Float.infinity && times > 0 else { return }

        let denominator = Double(times - 1) * Double(duration) / Double(divider) * Double(NSEC_PER_SEC)
        let deadline = DispatchTime.now() + denominator
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            timer.invalidate()
        }
    }

    /**
     水の中に雫を落とすように、雫はただの一度しか波紋を生成しない。
     - Parameter center: 波紋の中心点
     - Parameter view: 波紋があらわれるビュー
     - Parameter duration: (任意)  それぞれの波紋効果の時間　標準は2
     - Parameter size: (任意) 波紋の初期サイズ　標準は50
     - Parameter multiplier: (任意) 終了サイズを知るのに適用される乗算子　標準は4
     - Parameter color: (任意) 波紋の色　標準は白
     - Parameter border: (任意)  波紋のボータの幅　標準は2.25

     - Returns: 波紋オブジェクト,仕様用途としては内部的なため、いじれない
     */
    private func droplet(_ center: CGPoint, view: UIView,
                        duration: TimeInterval = 2,
                        size: CGFloat = 50, multiplier: CGFloat = 4,
                        color: UIColor = UIColor.white, border: CGFloat = 2.25) -> Ripple {

        let ripple = Ripple(center: center, view: view,
                            duration: duration,
                            size: CGSize(width: size, height: size),
                            multiplier: multiplier,
                            color: color,
                            border: border)

        ripple.activate()

        return ripple
    }

    /**
     現在のタイマーを全て停止する
     */
    public func calm() {
        timers.forEach { $0.invalidate() }
        timers.removeAll()
    }
}



/**
 波紋
 */
/// @ACCESS_OPEN
open class Ripple: NSObject {
    
  /// 中心
  var center: CGPoint
    
  /// 波紋を表示するビュー
  var view: UIView
  
  /// 時間
  var duration: TimeInterval
    
  /// サイズ
  var size: CGSize
  
  /// 乗算子
  var multiplier: CGFloat
    
  /// 色
  var color: UIColor
    
  /// ボーダー
  var border: CGFloat
    
  /// 波紋リスト
  var ripples: [UIView] = []

    
  /// initializer
  ///
  /// - Parameters:
  ///   - center: center
  ///   - view: view
  ///   - duration: duration
  ///   - size: size
  ///   - multiplier: multiplier
  ///   - color: color
  ///   - border: border
  init(center: CGPoint, view: UIView,
       duration: TimeInterval, size: CGSize,
       multiplier: CGFloat, color: UIColor, border: CGFloat) {

    self.center = center
    self.view = view
    self.duration = duration
    self.size = size
    self.multiplier = multiplier
    self.color = color
    self.border = border
  }

  /// 活性化
  func activate() {
    let ripple = UIView()

    if let subview = view.subviews.first {
      view.insertSubview(ripple, aboveSubview: subview)
    } else {
      view.insertSubview(ripple, at: 0)
    }

    ripple.frame.origin = CGPoint(x: center.x - size.width / 2,
                                  y: center.y - size.height / 2)
    ripple.frame.size = size
    ripple.layer.borderColor = color.cgColor
    ripple.layer.borderWidth = border
    ripple.layer.cornerRadius = ripple.bounds.width / 2
    ripple.backgroundColor = UIColor(cgColor: color.cgColor)
    ripple.alpha = view.alpha

    let animation = CABasicAnimation(keyPath: "cornerRadius")
    animation.fromValue = ripple.layer.cornerRadius
    animation.toValue = size.width * multiplier / 2

    let boundsAnimation = CABasicAnimation(keyPath: "bounds.size")
    boundsAnimation.fromValue = NSValue(cgSize: ripple.layer.bounds.size)
    boundsAnimation.toValue = NSValue(cgSize: CGSize(width: size.width * multiplier, height: size.height * multiplier))

    let opacityAnimation = CAKeyframeAnimation(keyPath: "opacity")
    opacityAnimation.values = [0, 1, 1, 1, 0]

    let animationGroup = CAAnimationGroup()
    animationGroup.animations = [animation, boundsAnimation, opacityAnimation]
    animationGroup.duration = duration
    animationGroup.delegate = self
    animationGroup.timingFunction = CAMediaTimingFunction(controlPoints: 0.22, 0.54, 0.2, 0.47)
    animationGroup.isRemovedOnCompletion = false
    animationGroup.fillMode = kCAFillModeForwards

    ripples.append(ripple)
    ripple.layer.add(animationGroup, forKey: "ripple")
  }
    
  /// タイマー発火
  func timerDidFire() {
    activate()
  }
}

// MARK: - CAAnimationDelegate
extension Ripple: CAAnimationDelegate {

  /**
   波紋をよりよくするための、アニメーションの移譲メソッド
   */
  open func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    guard let ripple = ripples.first else { return }

    ripple.alpha = 0
    ripple.removeFromSuperview()
    ripple.layer.removeAnimation(forKey: "ripple")

    ripples.removeFirst()
  }
}
