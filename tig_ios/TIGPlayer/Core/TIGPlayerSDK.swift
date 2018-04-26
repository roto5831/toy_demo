//
//  TIGPlayerSDK.swift
//  TIGPlayer
//

import Alamofire
import PromiseKit
import SwiftyJSON


/// Config
public class TIGSDK_Config {
    open static var metaDomain:String = ""
    open static var metaNextDomain:String = ""
    open static var contentsItemDomain:String = ""
    open static var contentsListDomain:String = ""
}

/// StockItem
open class TIGSDK_StockItem {
    /// itemId
    open var itemId = ""
    
    /// contentsId
    open var contentsId = ""
    
    /// thumbnailURL
    open var itemThumbnailURL = ""
    
    /// itemTitle
    open var itemTitle = ""
    
    /// wipeモード時に表示されるURL
    open var itemWebURL = ""
}

/// Player
open class TIGSDK_Player {
    
    /// モード
    ///
    /// - close: mode
    /// - blink: mode
    public enum modeState: Int {
        case close = 0
        case blink = 1
    }

    open var enableToggleMode = true{
        didSet{
            if self.player != nil {
                self.player.enableToggleMode = self.enableToggleMode
            }
        }
    }
    
    open var tigMode = modeState.close{
        didSet{
            if self.player != nil {
                self.player.tigMode = self.tigMode.rawValue
            }
        }
    }

    open var showShareButton = true{
        didSet{
            if self.player != nil {
                self.player.showShareButton = self.showShareButton
            }
        }
    }
    
    open var enableWipe = true{
        didSet{
            if self.player != nil {
                self.player.enableWipe = self.enableWipe
            }
        }
    }
    
    var player: TIGPlayer!
    
    
    public init() {
        
    }
    
    open func playWithURL(contents: Content, contentView: UIView? = nil) {
        var currentContent = PersistentManager.getByPrimaryKey(CurrentContent.self,primaryKey:PersistentManager.PersistentCosnt.PrimaryKey.CurrentContent.rawValue)
        if let  _ = currentContent{
        }else{
            currentContent = CurrentContent()
        }
    
        PersistentManager.update(currentContent){
            currentContent!.contentsId = contents.contentsId
            currentContent!.videoUrl = contents.videoUrl
            currentContent!.videoShotPrev = contents.videoShotPrev
            if let contentsDesc = contents.contentsDesc{
                currentContent!.contentsDesc = contentsDesc
            }
            if let contentsTitle = contents.contentsTitle{
                currentContent!.contentsTitle = contentsTitle
            }
            if let groupIdent = contents.groupIdent{
                currentContent!.groupIdent = groupIdent
            }
        }
        
        // 動画urlとcontentsIdを取得して動画再生する
        guard let url = URL.init(string: contents.videoUrl), let contentsId = contents.contentsId else {
            return
        }
        
        self.player?.computedPlayerView.removeFromSuperview()
        self.player = nil
        
        self.player = TIGPlayer(contentsId: contentsId)
        self.player!.playWithURL(url, contentView: contentView)
        self.player.tigMode = self.tigMode.rawValue
        self.player.enableToggleMode = self.enableToggleMode
        self.player.showShareButton = self.showShareButton
        self.player.enableWipe = self.enableWipe
    }
    
    open func getStockItems() -> [TIGSDK_StockItem] {
        var stockItems: [TIGSDK_StockItem] = []
        
        if let currentContent = PersistentManager.getFirst(CurrentContent.self){
            if let items =  PersistentManager.getByPrimaryKey(Items.self, primaryKey: currentContent.contentsId){
                let box = items.populate()
                box.forEach{ item in
                    let stockItem = TIGSDK_StockItem()
                    stockItem.contentsId = item.contentsId
                    stockItem.itemId = item.itemId
                    stockItem.itemThumbnailURL = item.itemThumbnailURL
                    stockItem.itemTitle = item.itemTitle
                    stockItem.itemWebURL = item.itemWebURL
                    stockItems.append(stockItem)
                }
            }
        }
        
        return stockItems
    }
    
    open func setStockItems(stockItems: [TIGSDK_StockItem]) {
        if let currentContent = PersistentManager.getFirst(CurrentContent.self){
            // Delete all ItemModel and Items
            let oldItems:Items? = PersistentManager.getByPrimaryKey(Items.self, primaryKey: currentContent.contentsId)
            if (oldItems != nil) {
                for item in (oldItems?.list)! {
                    PersistentManager.delete(ItemModel.self, primaryKey: "\(currentContent.contentsId)\(item.itemId)")
                }
            }
            
            PersistentManager.delete(Items.self, primaryKey: currentContent.contentsId)
            
            
            // Make new ItemModel and Items
            var items:Items? = PersistentManager.getByPrimaryKey(Items.self, primaryKey: currentContent.contentsId)
            if let  _ = items{
            }else{
                items = Items()
            }
            
            PersistentManager.update(items){
                items!.contentsId = currentContent.contentsId
            }
            
            for stockItem in stockItems {
                var itemModel:ItemModel? = PersistentManager.getByPrimaryKey(ItemModel.self, primaryKey: "\(currentContent.contentsId)\(stockItem.itemId)")
                if let  _ = itemModel{
                }else{
                    itemModel = ItemModel()
                }
                PersistentManager.update(itemModel){
                    itemModel!.itemId = stockItem.itemId
                    itemModel!.contentsId = currentContent.contentsId
                    itemModel!.itemThumbnailURL = stockItem.itemThumbnailURL
                    itemModel!.itemWebURL = stockItem.itemWebURL
                    itemModel!.itemTitle = stockItem.itemTitle
                }
                PersistentManager.update(items){
                    items!.insert(itemModel!, index: items!.count)
                }
            }
            
            TIGNotification.post(TIGNotification.stock)
        }
    }
    
}

/// ApiClient
open class TIGSDK_ApiClient {
    open static func getContentsList() -> Promise<Any> {
        let url = "https://" + TIGSDK_Config.contentsListDomain;
        
        return Promise {
            fulfill, reject in
            Alamofire.request("\(url)")
                .responseJSON(completionHandler: {
                    response in
                    
                    TIGLog.info(message:"ApiExecute")
                    TIGLog.debug(message:"URL", anyObject:url)
                    TIGLog.debug(message:"ResponseJSON", anyObject:response.result)
                    
                    switch response.result {
                    case .success(let value):
                        if response.response?.statusCode == 200 {
                            TIGLog.debug(message:"Success StatusCode", anyObject:response.response?.statusCode ?? "FailStatusCode")
                            
                            var contentsList = [Content]()
                            var json = JSON(value)
                            
                            print(json)
                            if let jsonDic = json["body"]["contents_list"].array{
                                jsonDic.forEach{content in
                                    if let content = Content(JSON: content.dictionaryObject!){
                                        contentsList.append(content)
                                    }
                                }
                            }
                            
                            fulfill(contentsList)
                        }
                        break
                    case .failure(let error):
                        reject(error)
                        TIGLog.debug(message:"Fail StatusCode", anyObject:response.response?.statusCode ?? "FailStatusCode")
                        TIGLog.error(message:"API NetworkError", anyObject:error)
                        break
                    }
                })
        }
    }
}
