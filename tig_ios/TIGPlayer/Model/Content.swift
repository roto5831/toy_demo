//
//  Content.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/07/06.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import Foundation
import ObjectMapper

/// 現在再生されているコンテンツを永続化
open class CurrentContent:PM,Mappable{

    /// primary key
    open dynamic var key = PersistentManager.PersistentCosnt.PrimaryKey.CurrentContent.rawValue
    
    /// contentsId
    open dynamic var contentsId = ""
    
    /// contents名
    open dynamic var contentsDesc = ""
    
    /// contentsタイトル
    open dynamic var contentsTitle = ""
    
    /// グループ識別子
    open dynamic var groupIdent = ""
    
    /// contents動画URL
    open dynamic var videoUrl = ""
    
    /// contents動画プレビュー画像
    open dynamic var videoShotPrev = ""
    
    /// initializer
    convenience required public init?(map: Map) {
        self.init()
        mapping(map: map)
    }

    /// jsonからのコンバート
    ///
    /// - Parameter map: map
    open func mapping(map: Map) {
    }

    /// PrimaryKeyの列名
    ///
    /// - Returns: column name
    override open static func primaryKey() -> String? {
        return PersistentManager.PersistentCosnt.PrimaryKeyColumn
    }
}

/// コンテンツ情報
open class Content:Mappable{
    
    /// contentsId
    open var contentsId : String!{
        get{
            return contentsIdent
        }
    }
    /// コンテンツ識別子（メタデータAPI取得用の引数に指定するid）
    open var contentsIdent: String!
    
    /// contentsIdIntVal
    open var contentsIdIntVal : Int!
    
    /// contents再生総時間
    open var contentsDuration : Double!{
        return Double(contentsDurationStrval)
    }
    
    /// contents再生総時間
    open var contentsDurationStrval : String!
    
    /// contents動画URL
    open var videoUrl : String!
    
    /// contents動画プレビュー画像
    open var videoShotPrev : String!
    
    /// root名:未実装　ストーリー分岐用
    open var rootName : String?
    
    /// rootタイトル:未実装　ストーリー分岐用
    open var rootTitle : String?
    
    /// root説明:未実装　ストーリー分岐用
    open var rootDescription : String?
    
    /// contents名
    open var contentsDesc : String?
    
    /// contentsタイトル
    open var contentsTitle : String?
    
    /// contents画像
    open var contentsImage : String?
    
    /// 最終更新日時
    open var contentsUpd : String!
    
    /// グループID
    open var groupId: String!
    
    /// グループ識別子
    open var groupIdent: String!
    
    
    /// 登録日時
    open var contentsCrt: String!
    
    /// initializer
    convenience required public init?(map: Map) {
        self.init()
        self.mapping(map: map)
    }
    
    /// jsonからのコンバート
    open  func mapping(map: Map) {
        self.contentsIdIntVal <- map["cid"]
        self.contentsIdent <- map["ident"]
        self.contentsImage <- map["img"]
        self.contentsTitle <- map["title"]
        self.videoUrl <- map["movie"]
        self.videoShotPrev <- map["thumb"]
        self.contentsDesc <- map["desc"]
        self.contentsDurationStrval <- map["dur"]
        self.contentsUpd <- map["upd"]
        self.groupId <- map["gid"]
        self.groupIdent <- map["gind"]
        self.contentsCrt <- map["crt"]
    }
}
