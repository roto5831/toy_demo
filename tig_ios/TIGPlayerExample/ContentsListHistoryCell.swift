//
//  ContentsListHistoryCell.swift
//  TIGPlayerExample
//
//  Created by ks on 2017/10/31.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import SDWebImage
import TIGPlayer

protocol ContentsListHistoryCellDelegate:class {
    func selectItem(sender: ContentsListHistoryCell, selectedItem:Item)
}

class ContentsListHistoryCell: UICollectionViewCell, UICollectionViewDataSource, UICollectionViewDelegate {

    /// サムネイルの画像
    @IBOutlet weak var thumbnailImage: UIImageView!
    
    /// タイトルのラベル
    @IBOutlet weak var titleLabel: UILabel!
    
    /// 再生時間のラベル
    @IBOutlet weak var timeLabel: UILabel!
    
    /// ストックのコレクションビュー
    @IBOutlet weak var collectionView: UICollectionView!
    
    /// コンテンツ
    public var content: Content! = nil
    
    /// アイテムリスト
    var box = [Item]()
    
    /// デリゲート
    weak var delegate:ContentsListHistoryCellDelegate? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        let nib = UINib(nibName: "ContentsListHistoryStockCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "ContentsListHistoryStockCell")
    }
    
    public func reloadStockItems() {
        if let items = PersistentManager.getByPrimaryKey(Items.self, primaryKey:self.content.contentsId){
            self.box = items.populate()
            self.collectionView.reloadData()
        }
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ContentsListHistoryStockCell", for: indexPath) as! ContentsListHistoryStockCell
        let item = self.box[indexPath.row % self.box.count]
        cell.thumbnailImage.sd_setImage(with: URL(string: item.itemThumbnailURL))
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.box.count
    }
    
    // MARK: - UICollectionViewDelegate
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = box[indexPath.item % self.box.count]
        self.delegate?.selectItem(sender: self, selectedItem: item)
    }
}
