//
//  ContentsShareButton.swift
//  Pods
//
//  Created by 唐 晶晶 on 2017/07/24.
//
//

import Foundation
import Accounts
import UIKit
import TIGPlayer

/// @ACCESS_OPEN
open class ContentsShareButton:UIButton,UIPopoverPresentationControllerDelegate {
    /// ステージング環境
    let stagingUrlStr = "https://stg.tigmedia.jp/stg_c/watch?id="
    
    /// 本番環境
    let productionUrlStr = "https://tigmedia.jp/watch?id="

    /// シェアURL
    var shareURL:URL?
    
    // MARK: -contentsIdが変化する度、シェアURLを更新-
    var contentsId: String?{
        didSet{
            if let currentContentsId = contentsId{
                var shareUrlStr:String?
                #if DEBUG
                    shareUrlStr = "\(self.stagingUrlStr)\(currentContentsId)"
                #else
                    shareUrlStr = "\(self.productionUrlStr)\(currentContentsId)"
                #endif
                if let urlStr = shareUrlStr {
                    self.shareURL = URL.init(string: urlStr)
                    NSLog("動画シェアURL：\(String(describing: self.shareURL))")
                }
            }
        }
    }
    
    // MARK:-イニシャライザ-
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // ボタンアクション設定
        self.addTarget(self, action: #selector(ContentsShareButton.shareMovie), for:.touchUpInside)
        // 現在コンテンツのcontentsIdを取得してshareURLを初期化する
        if let currentContentsId = self.contentsId {
            let urlStr = "\(self.productionUrlStr)\(currentContentsId)"
            self.shareURL = URL.init(string: urlStr)
            NSLog("動画シェアURL：\(String(describing: self.shareURL))")
        }
    }
    
    // MARK: -シェア処理-
    open func shareMovie() {
        let activityItems = [self.shareURL!] as [Any]
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
                activityVC.preferredContentSize = CGSize(width: 300, height: 300)
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
    
    /// Popover appears on iPhone
    public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
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
