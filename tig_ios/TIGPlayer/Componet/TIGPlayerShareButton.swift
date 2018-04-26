



//
//  TIGPlayerReplayButton.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/06/21.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

/// 共有ボタン
/// @ACCESS_OPEN
open class TIGPlayerShareButton:UIButton,UIPopoverPresentationControllerDelegate{
    
    /// TIGPlayer
    weak var player:TIGPlayer?
    
    /// Replyモード
    open var replayMode = false{
        didSet{
            if replayMode {
                self.setBackgroundImage(UIImage(named: "replay", in: Bundle(for:TIGPlayerShareButton.self), compatibleWith: nil), for:.normal)
            } else {
                self.setBackgroundImage(UIImage(named: "Share", in: Bundle(for:TIGPlayerShareButton.self), compatibleWith: nil), for:.normal)
            }
        }
    }
    
    
    /// initializer
    ///
    /// - Parameter frame: frame
    override init(frame:CGRect){
        super.init(frame:frame)
        self.frame.size = CGSize(width: TIGPlayerShareButton.side, height: TIGPlayerShareButton.side * 1.14)
        self.centeringIn(parentFrame: frame)
        self.initialize()
    }
    
    /// initializer
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    /// 初期化
    func initialize(){
        self.replayMode = false
        self.addTarget(self,action: #selector(TIGPlayerShareButton.onTouch), for:.touchUpInside)
    }
    
    /// 表示
    /// 親ビューの透明度を指定
    ///
    /// - Parameters:
    ///   - parentViewAlpha: parentViewAlpha
    ///   - replayViewhidden: replayViewhidden
    func display(parentViewAlpha:CGFloat,replayViewhidden:Bool){
        self.isHidden = replayViewhidden
        self.superview?.alpha = parentViewAlpha
        if self.isHidden{
            self.superview?.backgroundColor = UIColor.clear
        }else{
            self.superview?.backgroundColor = UIColor.black
        }
    }
    
    /// タッチ時
    func onTouch(){
        if replayMode {
            replay()
        } else {
            share()
        }
    }
    
    /// 動画をリプレイ
    func replay(){
        TIGNotification.post(TIGNotification.replay)
    }
    
    /// 動画を共有
    func share(){
        let contentsId = self.player?.contentsId
        var urlStr:String?
        #if DEBUG
            /// ステージング環境
            urlStr = "https://stg.tigmedia.jp/stg_c/watch?id="
        #else
            /// 本番環境
            urlStr = "https://tigmedia.jp/watch?id="
        #endif
        
        if let url = urlStr {
            let shareURL:URL = URL.init(string: "\(url)\(contentsId!)")!
            let activityItems = [shareURL] as [Any]
            
            // 初期化処理
            let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            
            // 使用しないアクティビティタイプ
            activityVC.excludedActivityTypes = [UIActivityType.airDrop,
                                                UIActivityType.addToReadingList,
                                                UIActivityType.assignToContact,
                                                UIActivityType.copyToPasteboard,
                                                UIActivityType.mail,
                                                UIActivityType.message,
                                                UIActivityType.postToTencentWeibo,
                                                UIActivityType.postToVimeo,
                                                UIActivityType.postToWeibo,
                                                UIActivityType.print,
                                                UIActivityType.init("com.apple.reminders.RemindersEditorExtension"),
                                                UIActivityType.init("com.apple.mobilenotes.SharingExtension"),
                                                UIActivityType.init("com.apple.iCloudDrive.ShareExtension"),
                                                UIActivityType.init("com.apple.mobileslideshow.StreamShareService")
            ]
            // parent UIViewControllerを取得してシェアシートを表示する
            if let viewController = self.viewController(responder: self){
                // UIActivityViewControllerを表示
                if UIDevice.current.userInterfaceIdiom == .pad {
                    activityVC.modalPresentationStyle = .popover
                    //set size
                    activityVC.preferredContentSize = CGSize(width: 300, height: 300)
                    //set arrow direction
                    activityVC.popoverPresentationController?.permittedArrowDirections = .init(rawValue: 0)
                    activityVC.popoverPresentationController?.sourceView = viewController.view
                    activityVC.popoverPresentationController?.sourceRect = CGRect.init(origin: CGPoint.init(x: viewController.view.frame.width/2 - 150,
                                                                                                            y: viewController.view.frame.height - activityVC.preferredContentSize.height),
                                                                                       size: activityVC.preferredContentSize)
                    //set delegate
                    activityVC.popoverPresentationController?.delegate = self
                }
                
                viewController.present(activityVC,
                                       animated: true,
                                       completion: {
                                        NSLog("シェアシート表示しました！")
                })
            }
        }
    }
    
    /// Popover appears on iPhone
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    /// 親フレームにセンタリング
    ///
    /// - Parameter parentFrame: parentFrame
    open func centeringIn(parentFrame:CGRect){
        self.center = CGPoint(x:parentFrame.midX, y:parentFrame.midY)
    }
    
    // MARK: -シェアボタンの親ビューコントロラーを取得-
    // -Parameter responder: ContentsShareButton-
    func viewController(responder: UIResponder) -> UIViewController? {
        if let vc = responder as? UIViewController {
            return vc
        }
        
        if let next = responder.next {
            return viewController(responder: next)
        }
        
        return nil
    }
    
}
