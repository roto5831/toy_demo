//
//  PersistentDataManager.swift
//  LibraryTest
//
//  Created by hirotomo on 2017/05/10.
//  Copyright © 2017 hirotomo. All rights reserved.
//

import Foundation
import RealmSwift
import ObjectMapper


/// PersistentModel
/// オブジェクト永続化(端末内のlocal storageもしくはDBへの保存)
/// Persistentの規約上、永続化されるオブジェクトはPersistentModelとして扱える必要がある
public typealias PM = Object


/// オブジェクト永続化規約
/// @ACCESS_PUBLIC
public protocol Persistent{
    
    /// PersistentModel更新
    ///
    /// - Parameters:
    ///   - model: PM
    ///   - logic: PM更新処理
    /// - Returns: void
    static func update<PM>(_ model: PM, logic:(() -> Void)?)
    
    /// PersistentModel複数件取得
    /// Filterで数を絞る
    ///
    /// - Parameters:
    ///   - type: PM
    ///   - predicateForFilter: filter
    /// - Returns: Results<PM>
    static func get<PM>(_ type:PM.Type,predicateForFilter:String?) -> Results<PM>
    
    
    /// PersistentModel削除
    ///
    /// - Parameters:
    ///   - type: PM
    ///   - primaryKey: primaryKey
    static func delete<PM>(_ type:PM.Type,primaryKey:String?)

}


/// オブジェクト永続化管理
/// Persistent protocolの規約に従い実装
/// @ACCESS_PUBLIC
public struct PersistentManager:Persistent{

    
    /// PersistentModel更新
    ///
    /// - Parameters:
    ///   - model: model description
    ///   - logic: logic description
    public static func update<PM>(_ model: PM, logic:(() -> Void)? = nil) {
        let sharedRealm = getPersistentAssistant()
        try! sharedRealm.write {
            if let logic = logic{
                logic()
            }
            sharedRealm.add(model as! Object , update: true)
        }
    }

    
    /// PersistentModelの最初の１件目取得
    ///
    /// - Parameters:
    ///   - type: PM
    ///   - predicateForFilter: filter
    /// - Returns: PM?
    public static func getFirst<PM>(_ type:PM.Type,predicateForFilter:String? = nil) -> PM?{
       let results = get(type as! Object.Type,predicateForFilter:predicateForFilter)
        if results.count > 0{
           return results[0] as? PM
        }else{
           return nil
        }
    }

    
    /// PersistentModel複数件取得
    ///
    /// - Parameters:
    ///   - type: PM
    ///   - predicateForFilter: filter
    /// - Returns: Results<PM>
    public static func get<PM>(_ type:PM.Type,predicateForFilter:String? = nil) -> Results<PM>{
        let sharedRealm = getPersistentAssistant()
        if let predicate = predicateForFilter{
            return sharedRealm.objects(type).filter(predicate)
        }else{
            return sharedRealm.objects(type)
        }
    }

    
    /// PersistentModelをKeyで取得
    ///
    /// - Parameters:
    ///   - type: PM
    ///   - primaryKey: primaryKey
    /// - Returns: PM?
    public static func getByPrimaryKey<PM>(_ type:PM.Type,primaryKey:String) -> PM?{
        let sharedRealm = getPersistentAssistant()
        return sharedRealm.object(ofType:type as! Object.Type, forPrimaryKey: primaryKey) as? PM
    }

    
    /// PersistentModelをKeyで削除
    ///
    /// - Parameters:
    ///   - type: PM
    ///   - primaryKey: primaryKey
    public static func delete<PM>(_ type:PM.Type,primaryKey:String? = nil){
        let sharedRealm = getPersistentAssistant()
        try! sharedRealm.write {
            if let primaryKey = primaryKey{
                if let pm = getByPrimaryKey(type, primaryKey: primaryKey){
                    sharedRealm.delete(pm as! Object)
                }
            }else{
                sharedRealm.delete(get(type as! Object.Type))
            }
        }
    }

    
    /// 登録されているPersistentModelを全削除
    public static func deleteAll(){
        let sharedRealm = getPersistentAssistant()
        try! sharedRealm.write {
            sharedRealm.deleteAll()
        }
    }


    ///　毎回インスタンスを新規で作成：別スレッドから同一インスタンスにアクセスするとエラーになる。
    ///  インスタンスは内部的にはスレッド毎にキャッシュされる。
    /// - Returns:Realm
    static func getPersistentAssistant() -> Realm{
        let realm = try!Realm()
        return realm
    }

}

