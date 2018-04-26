//
//  TIGPlayerWipeContainerRootViewController.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2016/01/16.
//  Copyright © 2016年 MMizogaki. All rights reserved.
//

import UIKit

///Wipe mode時の制御者
///階層
///TIGPlayerWipeContainerRootViewController
///     TIGPlayerWipeContainer
///         wipeWindow ※UIWindow
///     TIGPlayerView:cotroller.view.subview
///         controlView == TIGPlayerWipeView
/// @ACCESS_OPEN
open class TIGPlayerWipeContainerRootViewController: UIViewController {
    
    /// wipeContainer
    weak var wipeContainer: TIGPlayerWipeContainer!

    /// TIGPlayer
    weak var player:TIGPlayer?
    
    /// viewDidLoad
    override open func viewDidLoad() {
        super.viewDidLoad()
    }

    /// viewDidLoad
    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    /// 自動で回転すべきか
    override open var shouldAutorotate : Bool {
        return self.wipeContainer.shouldAutorotate
    }

    /// 対応している端末の向き
    override open var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return [.landscapeRight,.landscapeLeft,.portrait]
    }

    /// status bar 非表示
    override open var prefersStatusBarHidden: Bool{
        return true
    }

    /// videoView追加
    ///
    /// - Parameter view: TIGPlayerView
    open func addVideoView(_ view: UIView){
        view.removeFromSuperview()
        self.view.addSubview(view)
        view.frame = self.view.bounds
    }
}
