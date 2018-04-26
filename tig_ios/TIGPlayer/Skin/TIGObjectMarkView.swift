//
//  TIGObjectMarkView.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/04/13.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

/// blink mode時のTIGObject
class TIGObjectMarkView: UIView {
    /// ラベルのフォント
    private let font = UIFont.systemFont(ofSize: TIGObjectMarkView.fontSize)
    
    /// ラベルのテキスト
    /// テキストからViewの大きさを求める
    var labelText: String = "" {
        didSet{
            if labelText.count > TIGObjectMarkView.maxStringLength {
                innerLabelText = (labelText as NSString).substring(to: TIGObjectMarkView.maxStringLength) + "..."
            } else {
                if labelText.isEmpty {
                    innerLabelText = "Just TIG this!"
                } else {
                    innerLabelText = labelText
                }
            }
        }
    }
    
    /// 実際に描画されるテキスト
    private var innerLabelText: String = "" {
        didSet{
            calcFrame()
        }
    }
    
    /// initializer
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// initializer
    ///
    /// - Parameter frame: frame 
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = false
        self.isOpaque = false
        self.backgroundColor = UIColor.clear
    }
    
    /// 描画
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let context = UIGraphicsGetCurrentContext()
        drawBalloon(rect: rect, context: context!)
        drawText(rect: rect, context: context!)
    }
    
    /// サイズと位置の計算
    func calcFrame() {
        let margin = TIGObjectMarkView.balloonMargin * 2
        let maxSize = CGSize(width: UIScreen.main.bounds.width, height: 5000)
        let textSize = (innerLabelText as NSString).boundingRect(with: maxSize, options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                                 attributes: [NSFontAttributeName: font], context: nil).size
        let size = CGSize(width: textSize.width + margin, height: textSize.height + margin + TIGObjectMarkView.triangleSize.height)
        let superRect:CGRect = (self.superview?.frame)!
        let pos = CGPoint(x: superRect.width / 2 - size.width / 2, y: superRect.height / 2 + TIGObjectMarkView.triangleSize.height)
        self.frame = CGRect(origin: pos, size: size)
    }
    
    // ラベルの描画
    func drawText(rect: CGRect, context: CGContext) {
        self.innerLabelText.draw(at: CGPoint(x: TIGObjectMarkView.balloonMargin, y: TIGObjectMarkView.balloonMargin + TIGObjectMarkView.triangleSize.height),
                                 withAttributes: [NSForegroundColorAttributeName : UIColor.white, NSFontAttributeName : self.font,])
    }
    
    /// 吹き出しの描画
    func drawBalloon(rect: CGRect, context: CGContext) {
        let lx = rect.size.width - TIGObjectMarkView.triangleSize.width
        let rx = rect.size.width + TIGObjectMarkView.triangleSize.width
        let y = TIGObjectMarkView.triangleSize.height
        let triangleRightCorner = CGPoint(x: rx / 2.0, y: y + 1)
        let triangleTopCorner = CGPoint(x: rect.size.width / 2, y: 0)
        let triangleLeftCorner = CGPoint(x: lx / 2.0, y: y + 1)

        context.setFillColor(UIColor(red: 0, green: 0, blue: 0, alpha: 0.7).cgColor)
        
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y:TIGObjectMarkView.triangleSize.height, width:rect.width, height:rect.height - TIGObjectMarkView.triangleSize.height), cornerRadius: 4)
        path.fill()
 
        context.move(to: triangleLeftCorner)
        context.addLine(to: triangleTopCorner)
        context.addLine(to: triangleRightCorner)
        context.fillPath()
    }

}
