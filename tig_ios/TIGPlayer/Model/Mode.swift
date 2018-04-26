//
//  Mode.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/05/17.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import Foundation

/// TIGObject BlinkModeを永続化
class BlinkModeModel: PM{

    /// PrimaryKey
    dynamic var key = PersistentManager.PersistentCosnt.PrimaryKey.BlinkMode.rawValue
    
    /// OpenModeかどうか
    dynamic var flg = false

    /// PrimaryKeyの列名
    ///
    /// - Returns: column name
    override static func primaryKey() -> String? {
        return PersistentManager.PersistentCosnt.PrimaryKeyColumn
    }
}
/// TIGObject CloseModeを永続化
class CloseModeModel: PM {
    
    /// PrimaryKey
    dynamic var key = PersistentManager.PersistentCosnt.PrimaryKey.CloseMode.rawValue
    
    /// CloseModeかどうか
    dynamic var flg = false
    
    /// PrimaryKeyの列名
    ///
    /// - Returns: column name
    override static func primaryKey() -> String? {
        return PersistentManager.PersistentCosnt.PrimaryKeyColumn
    }
}
