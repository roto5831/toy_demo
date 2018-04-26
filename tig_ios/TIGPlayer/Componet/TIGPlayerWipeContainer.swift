//
//  TIGPlayerWipeContainer.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2016/01/16.
//  Copyright © 2016年 MMizogaki. All rights reserved.
//

import UIKit


/// TIGPlayerWipeWindow補完
/// @ACCESS_PUBLIC
public protocol TIGPlayerWipeWindowComplemtent:class{
    var computedFrame: CGRect { get }
}

/// TIGPlayerWipeWindow
/// @ACCESS_OPEN
open class TIGPlayerWipeWindow:UIWindow{
    
    /// TIGPlayerWipeWindow補完
    open weak var comp:TIGPlayerWipeWindowComplemtent?
    
    /// 端末回転時等にFrameの再計算
    open override func layoutSubviews() {
        if let comp = self.comp{
            self.frame = comp.computedFrame
        }
    }
}

/// TIGPlayerWipeContainer

/// Wipe mode時に必要な情報を保持したContainer
/// @ACCESS_OPEN
open class TIGPlayerWipeContainer:TIGPlayerWipeWindowComplemtent{
    
    /// Autorotation
    open var shouldAutorotate = true
    
    ///どの端末方向に対して対応するか
    open var supportedInterfaceOrientations:UIInterfaceOrientationMask = [.landscapeRight,.landscapeLeft,.portrait]
    
    /// wipe mode時のwindow
    private(set) var wipeWindow: TIGPlayerWipeWindow!
    
    
    /// 　動画に対してのディスプレイの長辺比
    private let longerSideRatioInDisplayAgainstVideo:CGFloat = 0.3
    
    /// frame
    public var computedFrame:CGRect{
        get{
            guard let ctr = self.wipeWindow.rootViewController as? TIGPlayerWipeContainerRootViewController,
            let player = ctr.player else {
                return CGRect(x: 0, y: 0, width: 0, height: 0)
            }
            var frame = CGRect(x: self.wipeWindow.frame.origin.x, y: self.wipeWindow.frame.origin.y, width: 0, height: 0)
            let size = deviceInfo.rawSize
            let videoSize = player.getPresentationVideoSize()
            if player.isVideoForLandscape{
                let longerSide = (deviceInfo.isLandScape ? size.width:size.height) * longerSideRatioInDisplayAgainstVideo
                let ratio = player.isValidPresentationVideoSize ? longerSide / videoSize.width:longerSideRatioInDisplayAgainstVideo
                let shorterSide = player.isValidPresentationVideoSize ? videoSize.height * ratio :(deviceInfo.isLandScape ? size.height:size.width) * ratio
                frame.size = CGSize(width: longerSide , height: shorterSide)
            }else{
                let longerSide = (deviceInfo.isLandScape ? size.width:size.height) * longerSideRatioInDisplayAgainstVideo
                let ratio = player.isValidPresentationVideoSize ? longerSide / videoSize.height:longerSideRatioInDisplayAgainstVideo
                let shorterSide = player.isValidPresentationVideoSize ? videoSize.width * ratio :(deviceInfo.isLandScape ? size.width:size.height) * ratio
                frame.size = CGSize(width: shorterSide, height: longerSide)
                
            }
            if frame.origin.x < 0{
                frame.origin.x = 0
            }
            if frame.origin.y < 0{
                frame.origin.y = 0
            }
            let cordinates = deviceInfo.largestCordinates
            if cordinates.maxX < frame.maxX {
                frame.origin.x = frame.origin.x - frame.size.width
            }
            if cordinates.maxY < frame.maxY {
                frame.origin.y = frame.origin.y - frame.size.height
            }
            return frame
        }
    }

    /// deinitialize
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.wipeWindow = nil
    }
    
    /// initialize
    ///
    /// - Parameters:
    ///   - frame: frame
    ///   - rootViewController: rootViewController
    init(rootViewController: TIGPlayerWipeContainerRootViewController) {
        rootViewController.wipeContainer = self
        self.wipeWindow = TIGPlayerWipeWindow()
        self.wipeWindow.rootViewController = rootViewController
        self.wipeWindow.backgroundColor = UIColor.clear
        self.wipeWindow.windowLevel = UIWindowLevelNormal + 1
        self.wipeWindow.clipsToBounds = true
        rootViewController.view.frame = self.computedFrame
        self.wipeWindow.frame = rootViewController.view.frame
        self.wipeWindow.comp = self
        self.adjustOrigin()
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.deviceOrientationDidChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.wipeHandlePan))
        self.wipeWindow.addGestureRecognizer(panGestureRecognizer)
    }

    /// 発端調整
    ///
    /// - Parameter frame: frame description
    func adjustOrigin(){
        let cordinates = deviceInfo.largestCordinates
        if let wipeWindow = self.wipeWindow{
            wipeWindow.frame.origin = CGPoint(x: cordinates.maxX - computedFrame.width , y: cordinates.maxY - computedFrame.height)
        }
    }

    /// panGesture
    ///
    /// - Parameter panGestureRecognizer: panGestureRecognizer
    @objc private  func wipeHandlePan(_ panGestureRecognizer: UIPanGestureRecognizer) {
        guard let moveView = panGestureRecognizer.view else {
            return
        }
        UIView.animate(withDuration: 0.1, animations: {() -> Void in
            if panGestureRecognizer.state == .began || panGestureRecognizer.state == .changed {
                var translation = panGestureRecognizer.translation(in: moveView)
                if moveView.frame.origin.x < 0{
                    if translation.x < 0{
                        translation.x = 0
                    }
                }
                if moveView.frame.origin.y < 0{
                    if translation.y < 0{
                        translation.y = 0
                    }
                }
                let cordinates = deviceInfo.largestCordinates
                if cordinates.maxX < moveView.frame.maxX {
                    if 0 < translation.x  {
                       translation.x = 0
                    }
                }
                if cordinates.maxY < moveView.frame.maxY {
                    if 0 < translation.y  {
                        translation.y = 0
                    }
                }
                moveView.center =  CGPoint(x:moveView.center.x + translation.x, y:moveView.center.y + translation.y)
                panGestureRecognizer.setTranslation(CGPoint.zero, in: moveView)
                
            }
        })
    }

    /// 表示
    ///
    /// - Returns: true
    @discardableResult func show() ->Bool {
        self.wipeWindow.isHidden = false
        return true
    }

    /// 隠す
    ///
    /// - Returns: true
    @discardableResult func hidden() ->Bool {
        self.wipeWindow.isHidden = true
        return true
    }

    // 端末方向変更
    @objc private func deviceOrientationDidChange(_ notification: Notification) {
        self.wipeWindow.setNeedsLayout()
    }
}
