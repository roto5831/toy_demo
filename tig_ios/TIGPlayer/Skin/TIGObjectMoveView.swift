//
//  TIGObjectMoveView.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/04/15.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

/// TIGObjectサイズ調整に必要な処理の補完
protocol TIGObjectComplement:VideoComplement{
    func calcSize()->Void
    func calcSizeForSelf()->Void
}

extension TIGObjectComplement{
    func calcSize() -> Void{
        guard let someView = self as? UIView else{
            return
        }
        if let comp = someView as? TIGObjectComplement{
            comp.calcSizeForSelf()
        }
        someView.subviews.forEach{view in
            if let comp = view as? TIGObjectComplement{
                comp.calcSize()
            }
        }
    }
    func getRectAdjustedToVideo() -> CGRect{
        let limit = 20
        var count = 0
        guard let someView = self as? UIView else{
            return CGRect()
        }
        guard var superView = someView.superview else{
            return someView.bounds
        }
        while(true){
            if let renderer = superView as? TIGObjectRenderView{
                if let comp = renderer.renderingComp{
                    return comp.getRectAdjustedToVideo()
                }else{
                    return renderer.bounds
                }
            }
            if let recSuper = superView.superview{
                superView = recSuper
            }
            count = count+1
            if count > limit{
                break
            }
        }
        return someView.bounds
    }
}
class TIGObject:UIView{
}
extension TIGObject:TIGObjectComplement{
    func calcSizeForSelf()->Void{
    }
}
class TIGObjectImage:UIImageView{
}
extension TIGObjectImage:TIGObjectComplement{
    func calcSizeForSelf()->Void{
    }
}
/// TIGObjectRenderViewに描画される最上位のTIGObject
/// 階層
/// TIGObjectMoveView
///     TIGObjectAreaView
///         TIGObjectView
///             TIGObjectThumbnail
///         TIGObjectMarkView
class TIGObjectMoveView: TIGObject {
    
    /// uniqueId
    /// 2018年1月31日時点、uidは実際アイテムメタデータ中のitem_group（アイテムグループ）
    var uid: String?
    
    /// TIGObjectAreaView
    public var areaView: TIGObjectAreaView?

    var computedCordinates: (x: Int, y: Int)?
    
    var meta:Meta?
    
    /// initializer
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// initializer
    ///
    /// - Parameter frame: frame
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        areaView = TIGObjectAreaView.init(frame: CGRect(x: CGRect.zero.origin.x,
                                                        y: CGRect.zero.origin.y,
                                                        width: frame.size.width,
                                                        height: frame.size.height))
        self.addSubview(areaView!)
    }
    
    override func calcSizeForSelf()->Void{
        if let meta = meta{
            //s,m,lサイズをメタデータに応じて取得
            let videoSize = self.getRectAdjustedToVideo()
            self.frame.size = metaSize.getSizeDependsOn(meta.size,videoSize:videoSize)
            self.areaView?.frame.size = self.frame.size
        }
    }

    /// dragイベントが発生していない時にObjectMoveViewのセンターをメタデータの座標に合わせる
    ///
    /// - Parameters:
    ///   - x: animation point x
    ///   - y: animation point y
    func animation(x:CGFloat, y:CGFloat) {
        if (self.areaView?.touching)! {
            return
        }
        
        // 移動量が多い場合は即時移動する
        let dx = abs(self.center.x - x)
        let dy = abs(self.center.y - y)
        if (dx >= 50) || (dy >= 50) {
            self.centering(x: x,y: y)
        }
        
        // 移動のアニメーション
        UIView.animate(withDuration: TIGObjectMoveView.duration, delay: 0, options:[.allowUserInteraction], animations: {
            () -> Void in
            self.centering(x: x,y: y)
        }, completion: {(_ finished: Bool) -> Void in

        })
    }

    
    /// センタリング
    ///
    /// - Parameters:
    ///   - x: x座標
    ///   - y: y座標
    func centering(x:CGFloat, y:CGFloat){
        self.center.x = x
        self.center.y = y
    }
    
    override func layoutSubviews() {
        if let computedCordinates = self.computedCordinates{
            self.calcSize()
            self.animation(x: CGFloat(computedCordinates.x), y: CGFloat(computedCordinates.y))
        }
    }
}





