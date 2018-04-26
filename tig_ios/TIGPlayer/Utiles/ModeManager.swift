//
//  ModeManager.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/04/27.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

/// TIGObjectモード管理者
class ModeManager: NSObject {

    /// クローズモード設定
    ///
    /// - Parameter mode: flg
    static func setCloseMode(mode:Bool) {
        var model = PersistentManager.getByPrimaryKey(CloseModeModel.self,primaryKey:PersistentManager.PersistentCosnt.PrimaryKey.CloseMode.rawValue)
        if model == nil{
            model = CloseModeModel()
        }
        PersistentManager.update(model){
            model!.flg = mode
        }
    }

    /// クローズモード取得
    ///
    /// - Returns: model.flg
    static func getCloseMode() -> Bool  {
        if let model = PersistentManager.getFirst(CloseModeModel.self){
            return model.flg
        }else{
            return ModeManager.closeModeDefo
        }
    }

    /// ブリンクモード設定
    ///
    /// - Parameter mode: flg
    static func setBlinkMode(mode:Bool) {
        var model = PersistentManager.getByPrimaryKey(BlinkModeModel.self,primaryKey:PersistentManager.PersistentCosnt.PrimaryKey.BlinkMode.rawValue)
        if model == nil{
            model = BlinkModeModel()
        }
        PersistentManager.update(model){
            model!.flg = mode
        }
    }

    /// ブリンクモード取得
    ///
    /// - Returns: model.flg
    static func getBlinkMode() -> Bool  {
        if let model = PersistentManager.getFirst(BlinkModeModel.self){
            return model.flg
        }else{
            return ModeManager.blinkModeDefo
        }
    }
}
