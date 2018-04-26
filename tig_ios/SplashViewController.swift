//
//  SplashViewController.swift
//  TIGPlayerExample
//
//  Created by 小林 宏知 on 2017/08/25.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit


/// スプラッシュ画像を表示するコントローラー
class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute:{
            let userDefault = UserDefaults.standard
            if userDefault.bool(forKey: "firstLaunch") {
                let storybord: UIStoryboard = UIStoryboard(name: "Tutorial", bundle: nil)
                if let ctr = storybord.instantiateInitialViewController(){
                    self.present(ctr, animated: false, completion: nil)
                }
            }else{
                let storybord: UIStoryboard = UIStoryboard(name: "ContentsListViewController", bundle: nil)
                if let ctr = storybord.instantiateInitialViewController(){
                    self.present(ctr, animated: false, completion: nil)
                }
            }
        })
    }
    
}
