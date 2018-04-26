//
//  SideMenuView.swift
//  TIGPlayerExample
//
//  Created by 唐 晶晶 on 2017/11/22.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import Foundation
import UIKit

class SideMenuViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var sideMenuTableView: UITableView!
    
    /// タップでサイドメニューを閉じるビュー
    var touchToCloseView:UIView? = nil
    
    override func viewDidLoad() {
        self.view.backgroundColor = UIColor.clear
        
        // 一枚透明なビューを挿入して、タッチしたらサイドメニューが閉じる
        touchToCloseView = UIView()
        touchToCloseView?.backgroundColor = UIColor.clear
        // 親ビューの長辺でサイズを決める
        let size = self.view.frame.width > self.view.frame.height ? self.view.frame.width : self.view.frame.height
        touchToCloseView?.frame = CGRect.init(x: 0,
                                              y: 0,
                                              width: size,
                                              height: size)
        // タップジェスチャー認識を付ける
        let oneTap:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self,
                                                                        action: #selector(self.tapToClose(sender:)))
        oneTap.numberOfTapsRequired = 1
        self.touchToCloseView?.addGestureRecognizer(oneTap)
        self.view.insertSubview(touchToCloseView!, at: 0)
        
        // テーブルビューのデリゲート、データソース指定
        sideMenuTableView.delegate = self
        sideMenuTableView.dataSource = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TutorialCell")
        switch indexPath.item {
        case 0:
            cell?.textLabel?.text = "チュートリアル"
            break
        case 1:
            cell?.textLabel?.text = "利用規約"
            break
        case 2:
            cell?.textLabel?.text = "プライバシーポリシー"
            break
        case 3:
            cell?.textLabel?.text = "アプリについて"
            break
        default:
            break
        }
        return cell!
    }
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.item {
        case 0:
            let storybord: UIStoryboard = UIStoryboard(name: "Tutorial", bundle: nil)
            if let ctr = storybord.instantiateInitialViewController(){
                let userDefault = UserDefaults.standard
                if !userDefault.bool(forKey: "showTutorial") {
                    userDefault.set(true, forKey: "showTutorial")
                }
                self.present(ctr, animated: false, completion: nil)
            }
            break
        case 1:
            // 利用規約
            guard let url = URL(string: "https://www.paronym.jp/news/terms-of-service/") else {
                return
            }

            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                // Fallback on earlier versions
            }
            break
        case 2:
            // プライバシーポリシー
            guard let url = URL(string: "https://www.paronym.jp/news/privacy-policy/") else {
                return
            }

            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                // Fallback on earlier versions
            }
            break
        case 3:
            // アプリについて
            let sb = UIStoryboard.init(name: "AboutAppViewController", bundle: Bundle.main)
            let aboutAppViewController:AboutAppViewController = sb.instantiateInitialViewController() as! AboutAppViewController
            aboutAppViewController.modalPresentationStyle = .overFullScreen
            self.present(aboutAppViewController,
                         animated: true,
                         completion: {
                            NSLog("アプリについてを表示しました！！！")
            })
            break
        default:
            break
        }
    }
    
    func tapToClose(sender: UITapGestureRecognizer){
        self.dismiss(animated: false, completion: nil)
    }
}
