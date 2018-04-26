//
//  TIGPlayerModeButton.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/07/20.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

/// ヘッダーメニュー表示、非表示ボタン
class TIGPlayerModeButton: UIButton {
    /// 次回モード
    var nextMode: mode = .blink
    
    /// TIGNotification
    let tigNotification = TIGNotification()
    
    /// 表示タイマー
    var timer:Timer? = Timer()
    
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
        self.addTarget(self,action: #selector(TIGPlayerModeButton.respondToButton), for:.touchUpInside)
        
        tigNotification.observe(TIGNotification.toggleBar) { [unowned self] in
            self.toggleBtnAnima()
        }
        tigNotification.observe(TIGNotification.showBar) { [unowned self] in
            self.show()
        }
        tigNotification.observe(TIGNotification.toggleMode) { [unowned self] in
            self.respondToButton(sender:self)
        }
    }
    
    /// awakeFromNib
    override func awakeFromNib() {
        switch self.nextMode {
        case .blink:
            self.setImage(TIGPlayerModeButton.blinkOffImage, for: .normal)
        case .close:
            self.setImage(TIGPlayerModeButton.blinkOnImage, for: .normal)
        }
    }

    /// 表示、非表示切り替え
    func toggleBtnAnima() {
        if isShown(){
            self.hide()
        }else{
            self.show()
        }
    }
    
    /// 表示
    func show(){
    }
    
    /// 非表示
    func hide(){
    }
    
    /// 表示されているかどうか
    ///
    /// - Returns: layer.opacity == 1
    func isShown() -> Bool{
        return self.layer.opacity == 1
    }
    
    /// モード切り替え
    func respondToButton(sender:UIButton?) {
        switch self.nextMode {
        case .blink:
            self.blink(sender: sender)
        case .close:
            self.close(sender: sender)
        }
    }
    
    /// ブリンクモードに切り替える
    ///
    /// - Parameter sender: モードボタン
    func blink(sender:UIButton?){
        self.setNeedsLayout()
        self.alpha = 1.0
        self.setImage(TIGPlayerModeButton.blinkOnImage, for: .normal)
        TIGNotification.post(TIGNotification.markBlink,payload:"5")
        self.nextMode = .close
    }
    
    /// クローズモードに切り替える
    ///
    /// - Parameter sender:モードボタン
    func close(sender:UIButton?){
        self.setNeedsLayout()
        self.alpha = 0.2
        self.setImage(TIGPlayerModeButton.blinkOffImage, for: .normal)
        TIGNotification.post(TIGNotification.markClose)
        self.nextMode = .blink
    }
}
