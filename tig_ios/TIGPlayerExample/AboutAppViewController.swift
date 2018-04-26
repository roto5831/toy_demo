//
//  AboutAppViewController.swift
//  TIGPlayerExample
//
//  Created by 唐 晶晶 on 2017/11/22.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import Foundation
import UIKit

class AboutAppViewController: UIViewController {
    /// AppVersion表示ラベル
    @IBOutlet weak var appVersionLabel: UILabel!
    /// 画面を閉じるボタン
    @IBOutlet weak var closeButton: UIButton!
    
    /// status bar style
//    override open var preferredStatusBarStyle: UIStatusBarStyle{
//        return UIStatusBarStyle.default
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let versionText:String = "Version. \(version)"
        self.setVersionLabel(versionText: versionText)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setVersionLabel(versionText: String){
        appVersionLabel.text = versionText
    }
    
    @IBAction func close(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func closeAboutApp(sender:UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

