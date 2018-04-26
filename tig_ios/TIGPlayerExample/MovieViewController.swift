//
//  MovieViewController.swift
//  TIGPlayerExample
//
//  Created by 藤原 章敬 on 2017/05/17.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import TIGPlayer

/// 動画プレビュー制御者
class MovieViewController: UIViewController {
    /// 説明
//    @IBOutlet weak var Discription: UITextView!
    
    /// プレビュー画像
    @IBOutlet weak var MovieImage: UIImageView!
    
    /// タイトル
    @IBOutlet weak var MovieTitle: UILabel!{
        didSet{
            self.MovieTitle.sizeToFit()
        }
    }
    
    /// 再生時間
    @IBOutlet weak var MovieTime: UILabel!
    
    /// ラベル位置などを調整するため、ストックエリアの高さ
    let stockAreaHeight:CGFloat = 75
    
    /// コードから動的に生成した場合、viewDidLoadが呼ばれないため一時的にこれらの変数に値を保存
    var titleStr:String!
    var image:UIImage!
    var descriptionStr:String!
    var duration:String!
    var url: URL!
    var stockAreaHidden:Bool = true {
        didSet{
            self.reloadLabels(hidden: self.stockAreaHidden)
        }
    }
    
    /// ロードされたタイミングで仮に保存した値をセット
    override func viewDidLoad() {
        super.viewDidLoad()
        self.MovieTitle.text = self.titleStr
        self.MovieTime.text = String(self.duration)
    }
    
    /// 表示される際にプレビュー画像をロード
    ///
    /// - Parameter animated: animated
    override func viewWillAppear(_ animated: Bool) {
        self.view.layoutIfNeeded()
        self.MovieImage.sd_setImage(with: url)
    }
    
    /// Movie title、Movie timeラベル位置調整
    ///
    /// - Parameter hidden: stockArea表示非表示
    func reloadLabels(hidden:Bool){
        if self.MovieTitle == nil {
            return
        }
        
        if hidden{
            self.MovieTitle.frame = CGRect.init(x: self.MovieTitle.frame.origin.x,
                                                y: self.view.frame.height - self.MovieTitle.frame.height - 10,
                                                width: self.MovieTitle.frame.size.width,
                                                height: self.MovieTitle.frame.size.height)
            
            self.MovieTime.frame = CGRect.init(x: self.MovieTime.frame.origin.x,
                                               y: self.view.frame.height - self.MovieTime.frame.height - 10,
                                               width: self.MovieTime.frame.size.width,
                                               height: self.MovieTime.frame.size.height)
        }else{
            // Adjust positions of current page's parts
            self.MovieTitle.frame = CGRect.init(x: self.MovieTitle.frame.origin.x,
                                                y: self.view.frame.height - self.stockAreaHeight - self.MovieTitle.frame.height + 5,
                                                width: self.MovieTitle.frame.size.width,
                                                height: self.MovieTitle.frame.size.height)
            
            self.MovieTime.frame = CGRect.init(x: self.MovieTime.frame.origin.x,
                                               y: self.view.frame.height - self.stockAreaHeight - self.MovieTime.frame.height + 5,
                                               width: self.MovieTime.frame.size.width,
                                               height: self.MovieTime.frame.size.height)
        }
    }
    
    /// layout処理終了
    override func viewDidLayoutSubviews() {
        // ※アプリ再起動時、layout描画が遅れる問題を解決するため、
        // 必ずこっちでもう一回ラベル位置調整処理を呼びます。
        reloadLabels(hidden: self.stockAreaHidden)
    }
}
