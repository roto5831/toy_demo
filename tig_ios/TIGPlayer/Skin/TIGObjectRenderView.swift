//
//  TIGObjectLayerView.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/06/06.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import Foundation
import UIKit

protocol VideoComplement:class{
    /// 動画自体の縦横比率とデバイスの縦横縦横比率があっていない場合、動画比率に合わせた描画領域を取得
    ///
    /// - Returns: CGRect
    func getRectAdjustedToVideo() -> CGRect
}
/// TIGObject描画（配置）に必要な処理の補完
protocol TIGObjectRenderingComplement:VideoComplement{
    /// Sliderがまだ動いているかどうか
    ///
    /// - Returns:Bool
    func isProgressSliderStillSliding() -> Bool
    
    /// plyaerの現在時刻を取得
    ///
    /// - Returns: TimeInterval
    func getPlayerCurrentTime() -> TimeInterval?
    
    /// plyaerの状態を取得
    ///
    /// - Returns: TIGPlayer.TIGPlayerState
    func getPlayerCurrentState() -> TIGPlayer.TIGPlayerState?
    
    /// 動画データそのものの幅と高さとデバイス上の動画サイズの幅と高さからTIGObject描画座標計算に使用するscaleを取得
    /// メタデータの座標は動画データそのものの幅と高さを前提としているので、描画する際にデバイス上の動画サイズとの比率を考慮して描画座標計算する必要がある
    ///
    /// - Returns: (computedXpointScale,computedYpointScale)
    func getComputedMetaRenderingScale() -> (x:CGFloat,y:CGFloat)
}

/// TIGObject描画（配置）を担当
class TIGObjectRenderView: UIView {
    
    /// metaList
    var metaList: [String: [Meta]]? = [:]
    
    /// itemList
    var itemList: [String: Item]? = [:]
    
    /// uniqueId（アイテムメタデータキーitem_group）毎にTIGObjectMoveViewを保持
    var objectViewList: [String: TIGObjectMoveView] = [:]
    
    /// 重複したアイテムを表示しないためのitemIdセット
    var itemIdSet:Set<String> = []
    
    /// 描画（配置）補完
    weak var renderingComp:TIGObjectRenderingComplement?
    
    
    /// initializer
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    
    /// initializer
    ///
    /// - Parameter frame: frame
    override init(frame: CGRect) {
        super.init(frame:frame)
        self.initialize()
    }

    
    /// 初期化
    func initialize(){
        self.adjustSizeToVideoLayer()
    }

    // Blinkを表示中か？
    public func activeBlink() -> Bool {
        for obj in objectViewList.values {
            if (obj.areaView?.activeBlink())! {
                return true
            }
        }
        
        return false
    }
    
    /// 現在の時間でTIGObject描画（配置）
    ///
    /// - Parameter currentTime: currentTime
    func renderTigObject(currentTime: Double){
        guard
            let metaList = self.metaList,
            metaList.count > 0,
            let itemList = self.itemList,
            itemList.count > 0
        else{
            return
        }
        let second = getSecondSynchedWithPlayer(in:currentTime)
        let nextSecond = String(Double(second)! + 0.1)
        guard let metaArray = metaList[second] else{
            self.removeViewsShouldNotAppear()
            return
        }
        guard let renderingComp = self.renderingComp else{
            return
        }
        // アイテムメタデータキーitem_groupリスト
        var metaUidList: [String] = []
        self.itemIdSet = []
        for (_, meta) in metaArray.enumerated() {
            guard let item = itemList[meta.itemId] else {
                continue
            }
            let uid = meta.uid
            metaUidList.append(uid)
            var view = self.objectViewList[uid]
            if view == nil {
                view = createTigMoveView(meta,item)
                self.insertSubview(view!, at: 0)
                view!.calcSize()
                self.objectViewList[uid] = view
                view?.areaView?.changeViewAppearance()
            } else {
                view?.computedCordinates = meta.computedCordinates
                view!.setNeedsLayout()
                if renderingComp.isProgressSliderStillSliding(){
                    view?.areaView?.invalidateTimers()
                    view?.areaView?.changeViewAppearance()
                }
            }
            view!.areaView?.playerState = renderingComp.getPlayerCurrentState()
        }
        self.removeViewsShouldNotAppear(metaUidList,self.metaList?[nextSecond])
    }

    /// playerと同期した秒数を返す
    ///
    /// - Returns: the incremental seconds in every 0.1 which is synchronized with player's current time
    func getSecondSynchedWithPlayer(in currentTime:Double) -> String{
        var second = String(round(currentTime * 10)/10)
        guard let renderingComp = self.renderingComp else{
            return second
        }
        let playerSecond = String(round((renderingComp.getPlayerCurrentTime())! * 10)/10)
        if second != playerSecond {
            second = playerSecond
        }
        return second
    }


    /// TigMoveViewを生成
    ///
    /// - Parameters:
    ///   - meta: meta description
    ///   - item: item description
    /// - Returns: return value description
    func createTigMoveView(_ meta:Meta,_ item:Item) -> TIGObjectMoveView{
        let computedCordinates = meta.computedCordinates
//        s,m,lサイズをメタデータに応じて取得
        let videoSize = renderingComp?.getRectAdjustedToVideo()
        let size = metaSize.getSizeDependsOn(meta.size,videoSize:videoSize)
        let view = TIGObjectMoveView.init(frame:CGRect(x: computedCordinates.x,
                                                       y: computedCordinates.y,
                                                       width:Int(size.width),
                                                       height:Int(size.height)))
        view.meta = meta
        view.areaView?.item = item
        view.centering(x: CGFloat(meta.x), y: CGFloat(meta.y))
        if ModeManager.getCloseMode() {
            view.areaView?.viewCloseMode(nil,duration:0.0)
        }
        return view
    }

    /// 重複したアイテムをモード変更せずに表示上クローズにする
    ///
    /// - Parameters:
    ///   - objectViewList: objectViewList description
    func makeDuplicateItemsAppearanceClosed(_ objectViewList:[String: TIGObjectMoveView]){
        let sorted = objectViewList.sorted(by: {Int($0.0)! < Int($1.0)!})
        sorted.forEach{pair in
            let itemId = pair.value.areaView?.item?.itemId
            self.makeDuplicateItemsAppearanceClosed(itemId!,pair.value)
        }
    }

    /// 重複したアイテムをモード変更せずに表示上クローズにする
    ///
    /// - Parameters:
    ///   - itemId: itemId description
    ///   - view: view description
    func makeDuplicateItemsAppearanceClosed(_ itemId:String,_ view:TIGObjectMoveView){
        if self.itemIdSet.contains(itemId){
            if let areaView = view.areaView{
                areaView.viewCloseMode(nil,duration:0.0)
                areaView.duplicateFlg = true
            }
        }else{
            self.itemIdSet.insert(itemId)
            view.areaView?.duplicateFlg = false
        }
    }


    /// 表示対象外のViewを除外
    ///
    /// - Parameter metaUidList:
    func removeViewsShouldNotAppear(_ metaUidList:[String]? = nil,_ nextMetaArray:[Meta]? = nil){
        let uidList = self.objectViewList.flatMap(){ $0.0 }
        if let metaUidList = metaUidList{
            self.removeNeedlessUids(uidList.subtracting(metaUidList))
            self.makeDuplicateItemsAppearanceClosed(self.objectViewList)
            self.removeViewsShouldNotAppearInZeroPointOneSecond(metaUidList,nextMetaArray)
            //全削除
        }else{
            self.removeNeedlessUids(uidList)
        }
    }


    /// 0.1秒後に同一のUidを持つViewが存在しない場合にそのViewを消す。
    ///
    /// - Parameters:
    ///   - metaUidList: metaUidList description
    ///   - nextMetaArray: nextMetaArray description
    func removeViewsShouldNotAppearInZeroPointOneSecond(_ metaUidList:[String],_ nextMetaArray:[Meta]? = nil){
        guard let nextMetaArray = nextMetaArray else{
            self.removeNeedlessUids(metaUidList)
            return
        }
        let nextMetaUidList = nextMetaArray.flatMap(){$0.uid}
        self.removeNeedlessUids(metaUidList){ metaUid in
            return nextMetaUidList.contains(metaUid)
        }
    }


    /// 必要ないUIDを消す
    ///
    /// - Parameter needlessUids: needlessUids description
    func removeNeedlessUids(_ needlessUids:[String],excluded:((_ metaUid:String) -> Bool)? = nil){
        for metaUid in needlessUids{
            if let excluded = excluded{
                if excluded(metaUid){
                    continue
                }
            }
            if let view = self.objectViewList[metaUid] {
                if let areaView = view.areaView{
                    if areaView.touching{
                        continue
                    }
                }
                view.removeFromSuperview()
                self.objectViewList.removeValue(forKey: metaUid)
            }
        }
    }
    
    ///動画自体の縦横比率に調整
    func adjustSizeToVideoLayer(){
        if let renderingComp = self.renderingComp{
            self.frame = renderingComp.getRectAdjustedToVideo()
            
        }
    }

}
