//
//  ContentsListViewController+UICollectionViewDataSouce.swift
//  TIGPlayerExample
//
//  Created by 藤原 章敬 on 2017/05/18.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import SDWebImage
import TIGPlayer

// MARK: - UICollectionViewDataSource
extension ContentsListViewController: UICollectionViewDataSource{
    //collectionViewの要素の数を返す
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.box.count
    }

    //collectionViewのセルを返す（必須）
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath as IndexPath) as! StockItemCell
        cell.backgroundColor = UIColor.clear
        let urlString = box[indexPath.item].itemThumbnailURL
        cell.deleteBtn.isHidden = !self.deleteMode
        cell.deleteMode = self.deleteMode
        cell.itemImage.contentMode = .scaleToFill
        cell.itemImage.translatesAutoresizingMaskIntoConstraints = true
        cell.itemImage.sd_setImage(with: NSURL(string:urlString)! as URL )
        cell.contentView.autoresizesSubviews = true
        cell.contentView.bringSubview(toFront: cell.deleteBtn)
        return cell
    }
    
    /// tapでアイテムを削除
    ///
    /// - Parameters:
    ///   - button: 削除ボタン
    ///   - event: touch
    @IBAction func buttonPressed(_ button: UIButton, forEvent event: UIEvent) {
        guard let touch = event.allTouches?.first else { return }
        let point = touch.location(in: self.itemCollectionView)
        NSLog("point: \(point)")
        // touch locationでcollection viewのindexを取得する
        let tappedIndexPath:IndexPath = self.itemCollectionView.indexPathForItem(at: point)!
        let itemIndex = tappedIndexPath.item
        NSLog("itemIndex:\(itemIndex)")
        //
        self.updateCurrentSelectedForDelete(
            itemid: box[itemIndex].itemId,
            selected: self.deleteMode,
            populate:true
        )
        self.deleteSelectedItems()
    }
}

/// Popover appears on iPhone
public func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
    return .none
}

// MARK: - UICollectionViewDelegate
extension ContentsListViewController: UICollectionViewDelegate {

    /// 通常モード
    ///  ストックアイテムに指定したURLをロード
    /// 削除モード
    ///  アイテムを選択した際に削除対象かどうかを切り替える
    ///
    /// - Parameters:
    ///   - collectionView: collectionView
    ///   - indexPath: indexPath
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (!self.deleteMode) {
            if let url = NSURL(string:box[indexPath.item].itemWebURL){
                UIApplication.shared.openURL(url as URL)
            }
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension ContentsListViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if deviceInfo.isIpad{
            return CGSize(width: 60.0, height: 100.0)
        }else{
            return CGSize(width: 60.0, height: 100.0)
        }
    }
}


