//
//  TIGStockListView.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/04/21.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit


/// Stock後のTIGobjectリスト
class TIGStockListView: UITableView,UITableViewDelegate,UITableViewDataSource {

    /// ストックしたアイテムリスト
    var box = [Item]()
    
    var lastAddItem: Item? = nil
    
    /// TIGNotification
    let tigNotification = TIGNotification()
    
    /// cell高さ調整距離
    let cellMargin:CGFloat = 8
    
    /// Wipeの有効・無効
    open var enableWipe = true
    
    override init(frame: CGRect, style: UITableViewStyle) {
        super.init(frame: frame, style:style)
        print("TIGStockListViewFrame:\(frame)")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// awakeFromNib
    override func awakeFromNib() {
        register(TIGStockListCell.self, forCellReuseIdentifier: NSStringFromClass(TIGStockListCell.self))
        delegate = self
        dataSource = self
        if #available(iOS 11.0, *){
            self.delaysContentTouches = true
//            self.contentInsetAdjustmentBehavior = .never
        }
        
        self.backgroundColor = UIColor.clear
        self.bounds.size = CGSize(width: TIGStockListCell.size + cellMargin, height: self.frame.size.height)
        print("TIGStockListViewBounds:\(self.bounds.debugDescription)")

        tigNotification.observe(TIGNotification.stock) { _ in
            self.addStockList()
        }
        
        if let currentContent = PersistentManager.getFirst(CurrentContent.self){
            if let items =  PersistentManager.getByPrimaryKey(Items.self, primaryKey: currentContent.contentsId){
                box = items.populate()
            }
        }
    }

    /// stockListに追加
    func addStockList() {
        if let currentContent = PersistentManager.getFirst(CurrentContent.self){
            if let items =  PersistentManager.getByPrimaryKey(Items.self, primaryKey: currentContent.contentsId){
                box = items.populate()
            }
        }
        
        if box.count > 0 {
            lastAddItem = box[0]
        } else  {
            lastAddItem = nil
        }
        
        self.reloadData()
    }

    //MARK: - UITableViewDataSource
    /// セクション数
    ///
    /// - Parameter tableView: tableView
    /// - Returns: numberOfSections
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    /// セクション毎の列数
    ///
    /// - Parameters:
    ///   - tableView: tableView
    ///   - section: section
    /// - Returns: numberOfRowsInSection
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return box.count
    }

    /// 列毎のセル
    ///
    /// - Parameters:
    ///   - tableView: tableView
    ///   - indexPath: indexPath
    /// - Returns: UITableViewCell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(TIGStockListCell.self), for: indexPath) as! TIGStockListCell
        cell.setImageWeb(urlString: box[indexPath.row].itemThumbnailURL )
        cell.backgroundColor = UIColor.clear
        cell.contentView.backgroundColor = UIColor.clear

        // Cellタッチ効かなくなっているため、Cell内itemImageViewにTapGestureを付ける
        let tapItemImage:UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(self.tapItem(sender:)))
        tapItemImage.numberOfTapsRequired = 1
        cell.itemImageView.addGestureRecognizer(tapItemImage)
        
        if box[indexPath.row] === lastAddItem {
            cell.addAnimationMode = true
        } else {
            cell.addAnimationMode = false
        }
        
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return TIGStockListCell.size + cellMargin
    }
    
    // セルのアニメーション
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if box[indexPath.row] === lastAddItem {
            let scaleTransform = CATransform3DScale(CATransform3DIdentity, 1.25, 1.25, 1.25)
            cell.layer.transform = scaleTransform
            
            UIView.animate(withDuration: 0.5) {
                cell.layer.transform = CATransform3DIdentity
            }
            lastAddItem = nil
        }
    }
    
    // MARK: - UITableViewDelegate
    /// ストックしたアイテムが選択された時
    ///　wipe modeに変更
    ///  linkoutしたことをAnalyticsに通知
    /// - Parameters:
    ///   - tableView: tableView
    ///   - indexPath: indexPath
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("didSelectRowAtに入りました！！！")
        tableView.deselectRow(at: indexPath, animated: true)
        
        TIGNotification.post(TIGNotification.linkout, from: nil, payload:[
            "scene": "player",
            "itemId": box[indexPath.row].itemId,
            "url": box[indexPath.row].itemWebURL
            ])
        
        if (enableWipe) {
            TIGNotification.post(TIGNotification.wipe, payload:box[indexPath.row].itemWebURL)
        } else {
            let url = URL(string:box[indexPath.row].itemWebURL)
            if( UIApplication.shared.canOpenURL(url!) ) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url!)
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }
    
    func tapItem(sender: UITapGestureRecognizer) {
        // Getting cell indexPath on swipe gesture
        let location:CGPoint = sender.location(in: self)
        guard let tapIndexPath:IndexPath = self.indexPathForRow(at: location) else {
            return
        }
        
        TIGNotification.post(TIGNotification.linkout, from: nil, payload:[
            "scene": "player",
            "itemId": box[tapIndexPath.row].itemId,
            "url": box[tapIndexPath.row].itemWebURL
            ])
        
        if (enableWipe) {
            TIGNotification.post(TIGNotification.wipe, payload:box[tapIndexPath.row].itemWebURL)
        } else {
            let url = URL(string:box[tapIndexPath.row].itemWebURL)
            if( UIApplication.shared.canOpenURL(url!) ) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url!)
                } else {
                    // Fallback on earlier versions
                }
            }
        }
    }
}
