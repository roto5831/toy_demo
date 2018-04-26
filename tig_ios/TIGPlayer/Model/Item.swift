//
//  Item.swift
//  TIGPlayer
//
//  Created by Yu Arai on 2017/04/25.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import Foundation
import SwiftyJSON
import RealmSwift
import ObjectMapper


/// TIGオブジェクトアイテムリストを永続化
open class Items:PM,Mappable{
    
    /// primary key
    open dynamic var key = ""
    
    /// contentsId
    open dynamic var contentsId = ""{
        didSet{
            key = contentsId
        }
    }
    
    /// ItemModels
    open let list = List<ItemModel>()
    
    /// count
    open var count:Int{
        return list.count
    }
    
    /// initializer
    convenience required public init?(map: Map) {
        self.init()
        mapping(map: map)
    }
    
    /// mapping
    ///
    /// - Parameter map: map
    open func mapping(map: Map) {
    }

    /// itemをlistに挿入
    ///
    /// - Parameters:
    ///   - item: item
    ///   - index: index
    open func insert(_ item: ItemModel,index:Int) {
        if let saved = PersistentManager.getByPrimaryKey(ItemModel.self, primaryKey: "\(contentsId)\(item.itemId)"){
            list.insert(saved, at: index)
        }else{
            list.insert(item, at: index)
        }
    }

    /// 指定したアイテムのキーのindexを返す
    ///
    /// - Parameter key: item's key
    /// - Returns: index
    open func indexOfKey(key:String) -> Int{
        var index = 0
        for item in list{
            if item.key == key{
                return index
            }
            index += 1
        }
        return 0
    }

    /// 指定したindexのアイテムを取り除く
    ///
    /// - Parameter index: index
    open func remove(index:Int){
        list.remove(objectAtIndex: index)
    }

    /// 指定したindexでアイテムを取得
    ///
    /// - Parameter index: index
    open subscript(index:Int) -> ItemModel {
        get {
            assert(list.count > index, "index out of range")
            return list[index]
        }
    }

    /// PrimaryKeyの列名
    ///
    /// - Returns: column name
    override open static func primaryKey() -> String? {
        return PersistentManager.PersistentCosnt.PrimaryKeyColumn
    }

    /// 永続化モデルから通常モデルへの変換
    ///
    /// - Returns: return value description
    open func populate() -> [Item]{
        var items = [Item]()
        self.list.forEach{ itemModel in
            let item = Item()
            item.itemId = itemModel.itemId
            item.itemIdInt = itemModel.itemIdInt
            item.contentsId = itemModel.contentsId
            item.itemThumbnailURL = itemModel.itemThumbnailURL
            item.itemTitle = itemModel.itemTitle
            item.itemWebURL = itemModel.itemWebURL
            item.currentSelectedStateForDelete = itemModel.currentSelectedStateForDelete
            item.stockTime = itemModel.stockTime
            items.append(item)
        }
        return items
    }
}

/// TIGオブジェクトアイテム情報を永続化
open class ItemModel: PM,Mappable {

    /// primary key
    open dynamic var key = ""
    
    /// itemId
    open dynamic var itemId = ""{
        didSet{
            self.key = "\(contentsId)\(itemId)"
        }
    }
    
    /// itemId
    open dynamic var itemIdInt = 0{
        didSet{
            self.itemId = "\(itemIdInt)"
        }
    }
    
    /// contentsId
    open dynamic var contentsId = ""{
        didSet{
            self.key = "\(contentsId)\(itemId)"
        }
    }
    
    /// thumbnailURL
    open dynamic var itemThumbnailURL = ""
    
    /// itemTitle
    open dynamic var itemTitle = ""
    
    /// wipeモード時に表示されるURL
    open dynamic var itemWebURL = ""
    
    /// contentsList画面で現在削除対象かどうか
    open dynamic var currentSelectedStateForDelete = false
    
    /// stockした時間
    open dynamic var stockTime = "00:00:00"
    
    /// initializer
    convenience required public init?(map: Map) {
        self.init()
        mapping(map: map)
    }

    /// jsonからのコンバート
    ///
    /// - Parameter map: map
    open func mapping(map: Map) {
        itemIdInt <- map["iid"]
        itemThumbnailURL <- map["thumbnail"]
        itemTitle <- map["title"]
        itemWebURL <- map["weburl"]
        currentSelectedStateForDelete <-  map["currentSelectedStateForDelete"]
    }

    /// PrimaryKeyの列名
    ///
    /// - Returns: column name
    override open static func primaryKey() -> String? {
        return PersistentManager.PersistentCosnt.PrimaryKeyColumn
    }
}

/// TIGオブジェクトアイテム情報
open class Item: Mappable {

    /// primary key
    open var key = ""
    
    /// itemId
    open var itemId = ""{
        didSet{
            self.key = "\(contentsId)\(itemId)"
        }
    }
    
    /// itemId
    open var itemIdInt = 0{
        didSet{
            self.itemId = "\(itemIdInt)"
        }
    }
    
    /// contentsId
    open var contentsId = ""{
        didSet{
            self.key = "\(contentsId)\(itemId)"
        }
    }
    
    /// thumbnailURL
    open var itemThumbnailURL = ""
    
    /// itemTitle
    open var itemTitle = ""
    
    /// wipeモード時に表示されるURL
    open var itemWebURL = ""
    
    /// storyFlag:未使用
    open var storyFlag = false
    
    /// contentsList画面で現在削除対象かどうか
    open var currentSelectedStateForDelete = false
    
    /// stockした時間
    open var stockTime = "00:00:00"

    /// initializer
    convenience required public init?(map: Map) {
        self.init()
        mapping(map: map)
    }
    
    /// jsonからのコンバート
    ///
    /// - Parameter map: map
    open func mapping(map: Map) {
        itemIdInt <- map["iid"]
        itemThumbnailURL <- map["thumbnail"]
        itemTitle <- map["title"]
        itemWebURL <- map["weburl"]
        currentSelectedStateForDelete <-  map["currentSelectedStateForDelete"]
    }
}
