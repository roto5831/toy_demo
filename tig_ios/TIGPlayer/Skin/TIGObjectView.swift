//
//  TIGObjectView.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/04/19.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import QuartzCore

/// open mode時のTIGObject
class TIGObjectView: TIGObject, CAAnimationDelegate{
    /// TIGNotification
    let tigNotifi = TIGNotification()
    /// item画像のサムネイル
    var thumb = TIGObjectThumbnail.init(frame:TIGObjectThumbnail.thumbnailSize)
    /// TIG矢印(2018.2.13修正:プロトタイプTIG動作に矢印表示しないため)
//    var arrow = TIGObjectStockPointer.init(frame: TIGObjectStockPointer.arrowFrame)
    /// item画像のラベル
    var label = UILabel.init(frame:TIGObjectThumbnail.thumbnailLabelSize)
    /// CAShapeLayerインスタンスを生成
    var circle: CAShapeLayer = CAShapeLayer()
    /// サムネイル周囲リンク太さ = サムネイルサイズのwidth / ringThickRatio
    let ringThickRatio:CGFloat = 12
    /// タッチしている状態かどうか
    var touching:Bool = false
    ///
    var finished:Bool = false
    
    var tappedCordinate: CGPoint?{
        didSet{
            if let tappedCordinate = self.tappedCordinate{
                self.center = tappedCordinate
                self.thumb.isHidden = false
                // 2018.2.13改修：プロトタイプTIG動作に矢印表示しません
//                self.arrow.isHidden = false
            }
            let yPosition = Double(self.frame.size.height/1.5)
            self.updownThumbPosition(positionY: -yPosition)
            // 2018.2.13改修：プロトタイプTIG動作に矢印表示しません
//            self.arrow.adjustCordinates(itemFrame: self.thumb.frame)
        }
    }

    ///initializer
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    ///initializer
    ///
    /// - Parameter frame: frame
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.calcSizeForSelf()
        thumb.addSubview(self.label)
        self.addSubview(thumb)
        
        self.isUserInteractionEnabled = false
        self.thumb.isUserInteractionEnabled = false
        
        // 2018.2.13改修：プロトタイプTIG動作に矢印表示しません
//        self.addSubview(self.arrow)
        
        // 2018.2.13改修：TIG動作始める通知を観察
        self.tigNotifi.observe(TIGNotification.tigAnimaStart) {_ in
            // サムネイル周囲色リンク描画
            //self.drawCircle()
        }
        
        // 2018.2.19改修：色リンク回すアニメキャンセル
        self.tigNotifi.observe(TIGNotification.tigAnimaCancel) { _ in
            self.circle.removeAllAnimations()
            self.circle.removeFromSuperlayer()
        }
    }
    
    override func calcSizeForSelf()->Void{
        let videoSize = getRectAdjustedToVideo()
        let size = metaSize.getSizeDependsOn(metaSize.m_square.rawValue,videoSize:videoSize)
        let thumbnailSizeAdjustedToVideo = CGSize(width: size.width, height: size.height)
        // 2018.2.13修正:サムネイルのwidth + 周囲リンクのwidth（サムネイルのサイズによりリンクの太さが変更する）
        self.frame.size = CGSize.init(width: (thumbnailSizeAdjustedToVideo.width + thumbnailSizeAdjustedToVideo.width/self.ringThickRatio),
                                      height: (thumbnailSizeAdjustedToVideo.height + thumbnailSizeAdjustedToVideo.height/self.ringThickRatio))
        self.thumb.frame.size = thumbnailSizeAdjustedToVideo
        self.thumb.layer.cornerRadius = thumb.frame.size.width/2
        self.thumb.clipsToBounds = true
        // 2018.2.13修正:プロトタイプTIG動作に矢印表示しないため
//        self.arrow.adjustCordinates(itemFrame: self.thumb.frame)
        self.label.frame.size = CGSize(width:size.width, height:20)
        self.label.sizeToFit()
        if !self.touching{
            if let superview = superview{
                self.centeringIn(parentFrame: superview.frame)
            }
        }
        self.label.frame.size = CGSize(width: size.width,height:20)
        self.label.sizeToFit()
    }
    
    /// サムネイル画像updown
    ///
    /// - Parameter positionY: positionY
    func updownThumbPosition(positionY:Double){
        if self.tappedCordinate != nil {
            self.thumb.frame.origin.y = CGFloat(positionY)
        } else {
            self.thumb.frame.origin.y = 0
        }
    }
    
    /// 親フレームにセンタリング
    ///
    /// - Parameter parentFrame: parentFrame
    open func centeringIn(parentFrame:CGRect){
        if self.tappedCordinate == nil {
            self.center = CGPoint(x:parentFrame.midX, y:parentFrame.midY)
        }
    }
    
    /// フェードアウトアニメーション
    ///
    /// - Parameter duration: duration
    func fadeOutAnimatinon(duration:Double) {
        self.layer.removeAllAnimations()
        
        UIView.animate(withDuration: duration, delay: 0.0, options: [], animations: { [weak self] in
            self?.alpha = 0.0
        }, completion: { (_) in
        })
    }
    
    /// 円描く
    func drawCircle() {
        let lineWidth: CGFloat = self.thumb.frame.size.width/self.ringThickRatio
        let viewScale: CGFloat = self.frame.size.width
        let radius: CGFloat = viewScale
        self.circle.path = UIBezierPath(roundedRect: CGRect.init(x: 0, y: 0, width: radius, height: radius), cornerRadius: radius / 2).cgPath
        self.circle.position = CGPoint.init(x: self.thumb.frame.origin.x - lineWidth/2, y: self.thumb.frame.origin.y - lineWidth/2)
        self.circle.lineWidth = lineWidth
        self.circle.fillColor = UIColor.clear.cgColor
        self.circle.strokeColor = UIColor.init(red: CGFloat(0)/255.0, green: CGFloat(255)/255.0, blue: CGFloat(255)/255.0, alpha: 1.0).cgColor
        let circleAnima = drawCircleAnimation(duration: 0.8, repeat: 1.0, flag: true)
        self.circle.add(circleAnima, forKey: "updateGageAnimation")
        self.layer.insertSublayer(self.circle, below: self.thumb.layer)
    }
    
    /// ゲージが増えると色変換アニメグループ生成
    func drawCircleAnimation(duration: TimeInterval, repeat: Float, flag: Bool) -> CAAnimationGroup {
        let drawAnim = CABasicAnimation.init(keyPath: "strokeEnd")
        drawAnim.duration = duration
        drawAnim.repeatCount = 1
        drawAnim.fromValue = 0
        drawAnim.toValue = 1
        drawAnim.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        drawAnim.isRemovedOnCompletion = flag;
        drawAnim.fillMode = kCAFillModeForwards;
        drawAnim.autoreverses = flag
        
        let colorAnima = CABasicAnimation.init(keyPath: "strokeColor")
        colorAnima.duration = duration
        colorAnima.repeatCount = 1
        colorAnima.fromValue = self.circle.strokeColor
        colorAnima.toValue = UIColor.init(red: CGFloat(127)/255.0, green: CGFloat(255)/255.0, blue: CGFloat(212)/255.0, alpha: 0.8).cgColor
        colorAnima.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
        colorAnima.isRemovedOnCompletion = flag;
        colorAnima.fillMode = kCAFillModeForwards;
        colorAnima.autoreverses = flag
        
        let animationGroup:CAAnimationGroup = CAAnimationGroup()
        animationGroup.delegate = self
        animationGroup.animations = [drawAnim, colorAnima]
        animationGroup.duration = duration
        animationGroup.isRemovedOnCompletion = flag
        animationGroup.fillMode = kCAFillModeForwards

        return animationGroup
    }
    
    // MARK: - CAAnimation Delegate -
    /// アニメ終了デリゲート
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if flag {
            self.finished = flag
            TIGNotification.post(TIGNotification.tigAnimaStop)
            self.finished = false
        }
    }
}
