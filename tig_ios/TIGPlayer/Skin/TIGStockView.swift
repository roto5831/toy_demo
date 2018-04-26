//
//  TIGPlayerStockView.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/04/20.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit


/// TIGStockViewのDelegate
protocol TIGStockViewDelegate: class {
    /// TIGStockViewの表示時
    ///
    func showStockView()
    
    /// TIGStockViewの非表示時
    ///
    func hideStockView()
}


/// StockArea
class TIGStockView: UIView{
    
    /// mode
//    private(set) var mode: showingMode = .disappearAuto
    
    /// TIGNotification
    let tigNotification = TIGNotification()
    
    /// ストックエリア表示し続け
    var keepShowing:Bool = false
    
    /// 下部のバーをリサイズ中か
//    var isResizingBottomBar:Bool = false
    
    /// 表示されていないとき
    var isHidding = true
    
    /// 閉じる処理のタイマー
    var timer:Timer? = Timer()
    
    /// TIGPlayerWideControlViewインスタンス
    weak var controlView :TIGPlayerWideControlView?
    
    /// Delegate
    weak var delegate: TIGStockViewDelegate?
    
    /// 最初の背景色
    var originBGColor:UIColor!
    
    /// グラデーション
    let gradientLayer: CAGradientLayer = CAGradientLayer()
    let lightColor = UIColor.init(white: 0, alpha: 0)
    let darkColor = UIColor.init(white: 0, alpha: 0.6)
    
    /// TIGPlayer
    weak var player: TIGPlayer?{
        didSet{
            self.controlView = self.player?.controlView as? TIGPlayerWideControlView
        }
    }
    
    /// stockListView
    var stockListView:TIGStockListView!
    
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var closeMaskView: UIView!
    
    ///initializer
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    ///initializer
    override func awakeFromNib() {
        self.tigNotification.observe(TIGNotification.stock) { _ in
            self.sliderPoint(sender: nil)
        }
        self.isUserInteractionEnabled = true
        self.hide()
        
        // stockListView初期化
        let listViewFrame = CGRect.init(x: TIGStockView.positionOfStockListView.x,
                                        y: TIGStockView.positionOfStockListView.y,
                                        width: (self.frame.width - TIGStockView.marginSpaceHorizontal),
                                        height: (self.frame.height - TIGStockView.marginSpaceVertical))
        
        self.stockListView = TIGStockListView.init(frame: listViewFrame, style: UITableViewStyle.plain)
        print("TIGStockListViewFrame: \(self.stockListView.frame)")
        
        // StoryBoard上設定された背景色を保存
        self.originBGColor = self.backgroundColor
        
        //closeMaskViewグラデーション
        let closeMastGradientLayer: CAGradientLayer = CAGradientLayer()
        closeMastGradientLayer.colors = [lightColor.cgColor, darkColor.cgColor]
        closeMastGradientLayer.frame = self.closeMaskView.bounds
        self.closeMaskView.layer.insertSublayer(closeMastGradientLayer, at: 0)
    }
    
    open override func layoutSubviews() {
        if self.isHidding {
            self.close()
        }else{
            if deviceInfo.isLandScape && deviceInfo.isIpohneX {
                self.frame = self.getFrameBasedOn(x: deviceInfo.rawSize.width - TIGStockView.areaWidth - self.stockListView.frame.width/2, areaWidth: TIGStockView.areaWidth + self.stockListView.frame.width/2)
            }else{
                self.frame = self.getFrameBasedOn(x: deviceInfo.rawSize.width - TIGStockView.areaWidth)
            }
        }
        
        self.stockListView.frame = CGRect.init(x: self.stockListView.frame.origin.x,
                                               y: self.stockListView.frame.origin.y,
                                               width: self.stockListView.frame.width,
                                               height: self.frame.height - TIGStockView.marginSpaceVertical)
        gradientLayer.frame = self.bounds
    }
    
    @IBAction func closeStockArea(_ sender: UIButton){
        self.close()
    }
    
    func hide(){
        let extra:CGFloat = 10
        self.frame = self.getFrameBasedOn(x: deviceInfo.rawSize.width + TIGStockView.areaWidth + extra)
    }
    
    /// 閉じる処理
    func close() {
        delegate?.hideStockView()
        UIView.animate(withDuration:TIGStockView.duration, delay:0, options: [.curveEaseIn], animations: {() -> Void in
            self.frame = self.getFrameBasedOn(x: deviceInfo.rawSize.width)
        })
        self.keepShowing = false
        self.isHidding = true
    }

    /// ストックエリア自動閉じる
    func closeLater() {
        self.close()
        self.gradientLayer.removeFromSuperlayer()
    }
    
    /// StockAreaをスライドさせる
    /// disappearAuto：TIGObjectをswipeしたとき。一定秒数経過後、stockArea閉じる。
    /// keepShowing：stockButtonを押したとき。stockAreaは表示されたまま。
    /// - Parameter sender: sender
    func sliderPoint(sender:UIButton?) {
        // ストックリストビューの高さ調整
        self.stockListView.frame = CGRect.init(x: self.stockListView.frame.origin.x,
                                               y: self.stockListView.frame.origin.y,
                                               width: self.stockListView.frame.width,
                                               height: self.frame.height - TIGStockView.marginSpaceVertical)

        if sender != nil{
            self.keepShowing = true
            self.closeButton.isHidden = false
            self.closeMaskView.isHidden = false
            self.backgroundColor = self.originBGColor
        }else{
            if !self.keepShowing{
                self.timer?.invalidate()
                self.timer = Timer.scheduledTimer( timeInterval: 2, target: self, selector: #selector(self.closeLater), userInfo: nil, repeats: false )
                self.closeButton.isHidden = true
                self.closeMaskView.isHidden = true
                self.layer.insertSublayer(self.makeBGGradientLayer(), at: 0)
            }
        }
        
        // 表示アニメーション
        delegate?.showStockView()
        UIView.animate(withDuration:TIGStockView.duration, delay:0, options: [.curveEaseIn], animations: {() -> Void in
            if deviceInfo.isLandScape && deviceInfo.isIpohneX {
                self.frame = self.getFrameBasedOn(x: deviceInfo.rawSize.width - TIGStockView.areaWidth - self.stockListView.frame.width/2, areaWidth:TIGStockView.areaWidth + self.stockListView.frame.width/2)
            }else{
                self.frame = self.getFrameBasedOn(x: deviceInfo.rawSize.width - TIGStockView.areaWidth)
            }
        }, completion:{ _ in
        })
        
        self.isHidding = false
    }
    
    /// x軸座標に基づくFrameの取得
    ///
    /// - Parameter x: x scordinate
    /// - Returns: CGRect
    func getFrameBasedOn(x:CGFloat, areaWidth:CGFloat = TIGStockView.areaWidth) -> CGRect{
        return CGRect(
            x: x,
            y: self.frame.origin.y,
            width: areaWidth,
            height:self.frame.size.height
        )
    }
    
    func makeBGGradientLayer() -> CAGradientLayer {
        // 背景グラデーション
        self.backgroundColor = UIColor.clear
        gradientLayer.colors = [self.darkColor.cgColor, self.lightColor.cgColor]
        gradientLayer.frame = self.bounds
        gradientLayer.startPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0.5)
        return gradientLayer
    }
}

