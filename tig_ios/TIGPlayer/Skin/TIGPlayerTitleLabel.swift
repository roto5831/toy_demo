//
//  TIGPlayerTitleLabel.swift
//  TIGPlayer
//
//  Created by 唐 晶晶 on 2017/11/02.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import Foundation

/// タイトルラベル
/// @ACCESS_OPEN
open class TIGPlayerTitleLabel: UILabel {
    /// TIGNotification
    let tigNotification = TIGNotification()
    
    /// 表示タイマー
    var timer:Timer? = Timer()
    
    /// TIGPlayerWideControlViewインスタンス
    weak var wideControlView :TIGPlayerWideControlView?
    
    /// TIGPlayer
    weak var player: TIGPlayer?{
        didSet{
            self.wideControlView = self.player?.controlView as? TIGPlayerWideControlView
        }
    }
    
    /// initializer
    ///
    /// - Parameter frame: frame
    override init(frame:CGRect){
        super.init(frame:frame)
    }
    
    /// initializer
    /// initializer
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        backgroundColor = UIColor.clear
        
        if let currentContent = PersistentManager.getByPrimaryKey(CurrentContent.self,primaryKey:PersistentManager.PersistentCosnt.PrimaryKey.CurrentContent.rawValue){
            var title = currentContent.contentsTitle
            if title.characters.count >  40 {
                title = title.substring(to: title.index(title.startIndex, offsetBy: 40))
            }
            self.text = title
        }
        
        tigNotification.observe(TIGNotification.toggleBar) { _ in
            self.toggleTitleAnima()
        }
        tigNotification.observe(TIGNotification.showBar) { _ in
            self.showTitle()
        }
    }
    
    /// 表示、非表示切り替え
    func toggleTitleAnima() {
        if isTitleShown(){
            self.hideTitle()
        }else{
            self.showTitle()
        }
    }
    
    /// 表示
    func showTitle(){
        UIView.animate(withDuration: 0.16, delay: 0, options: .curveEaseIn, animations: {
            self.layer.opacity = 1
        }, completion:{(bool:Bool) -> Void in
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer( timeInterval: 2, target: self, selector: #selector(self.hideTitle), userInfo: nil, repeats: false )
        })
    }
    
    /// 非表示
    func hideTitle(){
        UIView.animate(withDuration: 0.16, delay: 0, options: .curveEaseIn, animations: {
            self.layer.opacity = 0
        }, completion:nil)
    }
    
    /// 表示されているかどうか
    ///
    /// - Returns: layer.opacity == 1
    func isTitleShown() -> Bool{
        return self.layer.opacity == 1
    }
    
}
