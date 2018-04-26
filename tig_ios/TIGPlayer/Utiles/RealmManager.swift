//
//  RealmManager.swift
//  LibraryTest
//
//  Created by hirotomo on 2017/05/10.
//  Copyright © 2017 hirotomo. All rights reserved.
//

import Foundation
import RealmSwift

//sample
class MyClass: BaseRealmModel {
    dynamic var test = ""
}

protocol RealmModel{
    typealias RM = Object
}

public enum RealmCosnt: String {
    case primaryKey = "id"
}

class BaseRealmModel:RealmModel.RM{

    dynamic var id = 0

    override static func primaryKey() -> String? {
        return RealmCosnt.primaryKey.rawValue
    }
}

struct RealmManager{

    private static let sharedRealm = try!Realm()

    /// save and increment primary key
    ///
    /// - Parameter model: RM(realm model) which extends Object
    static func save<RM>(_ model:RM){
        try! sharedRealm.write {
            sharedRealm.add(incrementModelPK(model) as! Object)
        }
    }

    /// save as new or update
    ///
    /// - Parameter model: RM(realm model) which extends Object
    static func update<RM>(_ model:RM){
        try! sharedRealm.write {
            if hasModel(model){
                sharedRealm.add(model as! Object, update: true)
            }else{
                save(model)
            }
        }
    }

    static func get<RM>(_ type:RM.Type,primaryKey:Int) -> RM?{
        return sharedRealm.object(ofType:type as! Object.Type, forPrimaryKey: primaryKey) as? RM
    }

    static func get<RM>(_ type:RM.Type,predicateForFilter:String? = nil) -> Results<RM>{
        if let predicate = predicateForFilter{
            return sharedRealm.objects(type).filter(predicate)
        }else{
            return sharedRealm.objects(type)
        }
    }

    static func getLatest<RM>(_ type:RM.Type) -> RM?{
        return sharedRealm.object(ofType:type as! Object.Type, forPrimaryKey: getLatestPK(type)) as? RM
    }

    static func getLatestPK<RM>(_ type:RM.Type) -> Int{
        return sharedRealm.objects(type as! Object.Type).map{($0 as! BaseRealmModel).id}.max() ?? 0
    }

    private static func incrementPK<RM>(_ type:RM.Type) -> Int{
        return getLatestPK(type) + 1
    }

    private static func hasModel<RM>(_ model:RM) -> Bool{
        return getLatestPK(type(of: model)) == 0 ? false : true
    }

    private static func incrementModelPK<RM>(_ model:RM) -> RM{
        (model as? BaseRealmModel)?.id = incrementPK(type(of: model))
        return model
    }
}

