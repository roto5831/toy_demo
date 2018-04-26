//
//  TutorialViewController.swift
//  TIGPlayerExample
//
//  Created by 唐 晶晶 on 2017/11/21.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class TutorialViewController:UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate{
    var window: UIWindow?
    
    /// ページ制御者
    var pageViewController: UIPageViewController?
    
    /// TutorialPage配列
    var tutorialPages:[UIViewController] = []
    
    /// 現在のページNo
    var pageNumber = 0
    
    /// コンテンツリストスタートフラグ
    var startContentsList = false

    /// UserDefaultsインスタンス
    let userDefault = UserDefaults.standard
    
    /// チュートリアルのコンテナ
    /// UIPageViewControllerが埋め込まれている
    @IBOutlet weak var pageContainerView: UIView!
    
    /// ページドット
    @IBOutlet weak var pageControl: UIPageControl!
    
    /// 利用規約に同意してリンクラベル
    @IBOutlet weak var termsLinkLabel: UILabel!
    
    /// ページ遷移ボタン
    @IBOutlet weak var nextButton: UIButton!
    
    /// status bar 非表示
    override open var prefersStatusBarHidden: Bool{
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ContainerView に Embed した UIPageViewController を取得する
        self.pageViewController = childViewControllers[0] as? UIPageViewController
        self.pageViewController!.dataSource = self
        self.pageViewController!.delegate = self
        
        // page配列を生成
        let pageFirst = storyboard?.instantiateViewController(withIdentifier:"TutorialFirstPageViewController") as! TutorialFirstPageViewController
        let pageSecond = storyboard?.instantiateViewController(withIdentifier:"TutorialSecondPageViewController") as! TutorialSecondPageViewController
        let pageThird = storyboard?.instantiateViewController(withIdentifier:"TutorialThirdPageViewController") as! TutorialThirdPageViewController
        self.tutorialPages = [pageFirst, pageSecond, pageThird]
        self.pageViewController?.setViewControllers([self.tutorialPages[0]],
                                                    direction: .forward,
                                                    animated: true,
                                                    completion: nil)
        
        // 利用規約に同意してラベルに設定
        self.termsLinkLabel.isHidden = true
        self.termsLinkLabel.isUserInteractionEnabled = true
        let tapGR = UITapGestureRecognizer.init(target: self, action: #selector(tapTermsLink))
        self.termsLinkLabel.addGestureRecognizer(tapGR)
        
        let labelText = self.termsLinkLabel!.text!
        let attributedText = NSMutableAttributedString.init(string: labelText)
        attributedText.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.styleSingle.rawValue, range: NSMakeRange(0, 4))
        attributedText.addAttribute(NSForegroundColorAttributeName, value: UIColor.blue, range: NSMakeRange(0, 4))
        self.termsLinkLabel.attributedText = attributedText
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func showNext(_ sender: Any) {
        guard self.tutorialPages.count >= 0 else{
            return
        }
        let pageMax = self.tutorialPages.count
        
        if self.pageNumber == pageMax - 1 && self.startContentsList {
            if userDefault.bool(forKey: "firstLaunch") {
                userDefault.set(false, forKey: "firstLaunch")
            }
            
            if userDefault.bool(forKey: "showTutorial") {
                userDefault.set(false, forKey: "showTutorial")
            }
            
            // はじめるボタンを押すとコンテンツリスト画面を表示する
            let storybord: UIStoryboard = UIStoryboard(name: "ContentsListViewController", bundle: nil)
            if let ctr = storybord.instantiateInitialViewController(){
                self.present(ctr, animated: false, completion: nil)
            }
            self.startContentsList = false
        }
        
        if (self.pageNumber < pageMax - 1) {
            self.nextButton.setTitle("次へ", for: .normal)
            self.termsLinkLabel.isHidden = true
            self.pageNumber += 1
            
            if self.pageNumber == pageMax - 1 {
                self.nextButton.setTitle("はじめる", for: .normal)
                self.termsLinkLabel.isHidden = userDefault.bool(forKey: "showTutorial")
                self.startContentsList = true
            }
            
            self.pageViewController!.setViewControllers([self.tutorialPages[self.pageNumber]],
                                                        direction: .forward,
                                                        animated: true,
                                                        completion: nil)
        }
        
        self.pageControl.currentPage = self.pageNumber
    }
    
    func pageViewController(_ pageViewController:UIPageViewController, viewControllerBefore viewController:UIViewController) -> UIViewController? {
        print("\(viewController.description)")
        guard let index = self.tutorialPages.index(of: viewController) else {
            return nil
        }

        if index <= 0 {
            //1ページ目の場合
            return nil
        } else {
            //1ページ目じゃない場合は1ページ前に戻す
            return tutorialPages[index-1]
        }
    }
    
    func pageViewController(_ pageViewController:UIPageViewController, viewControllerAfter viewController: UIViewController) ->UIViewController? {
        guard let index = self.tutorialPages.index(of: viewController) else {
            return nil
        }
        
        if index >= self.tutorialPages.count-1 {
            //最終ページの場合
            self.startContentsList = true
            return nil
        } else {
            //最終ページじゃない場合は1ページ進める
            return tutorialPages[index+1]
        }
    }
    
    /// ページ移動終了後に現在のページNoを切り替える
    ///
    /// - Parameters:
    ///   - pageViewController: pageViewController
    ///   - finished: upon
    ///   - previousViewControllers: pre
    ///   - completed: completion Flag
    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        let index = tutorialPages.index(of: (pageViewController.viewControllers?.first)!)
        self.pageNumber = index!
        self.pageControl.currentPage = index!
        if self.pageNumber < self.tutorialPages.count - 1{
            self.nextButton.setTitle("次へ", for: .normal)
            self.termsLinkLabel.isHidden = true
        }else{
            self.nextButton.setTitle("はじめる", for: .normal)
            self.termsLinkLabel.isHidden = userDefault.bool(forKey: "showTutorial")
            self.startContentsList = true
        }
    }
    
    func tapTermsLink(sender: UITapGestureRecognizer){
        guard let url = URL(string: "https://www.paronym.jp/news/terms-of-service/") else {
            return
        }
        
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url)
        } else {
            // Fallback on earlier versions
        }
    }
}

/// @ACCESS_PUBLIC
public extension Notification.Name {
    static let playTutorial = Notification.Name(rawValue: "PlayTutorial")
}
