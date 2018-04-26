//
//  Meta.swift
//  TIGPlayer
//
//  Created by Yu Arai on 2017/04/25.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import Foundation
import SwiftyJSON
import ObjectMapper


/// TIGオブジェクト描画に必要なメタ情報
open class Meta:Mappable{
    
    public enum period:String{
        case now = "now"
        case next = "next"
    }
    
    /// 2018/1/31時点、uidはアイテムメタデータのitem_group（アイテムグループ）
    open var uid = ""
    /// itemId
    open var itemId = ""
    
    /// itemId
    open var itemIdInt = 0{
        didSet{
            self.itemId = "\(itemIdInt)"
        }
    }
    
    /// サイズ
    open var size = 0
    /// x座標
    open var x:Int = 0
    /// y座標
    open var y:Int = 0
    /// TIGオブジェクトが重なっている際の優先度:未実装　0-9の値
    open var z:Int = 0
    
    ///座標を実際のビデオのサイズと端末の表示サイズ比の縮尺に基づいて再計算
    open var computedCordinates:(x:Int,y:Int){
        get{
            let leftOperand = Float(self.x) * (Float(round(Meta.scale.x * 1000)/1000))
            let rightOperand = Float(self.y) * (Float(round(Meta.scale.y * 1000)/1000))
            guard
                !leftOperand.isInfinite,
                !leftOperand.isNaN,
                !rightOperand.isInfinite,
                !rightOperand.isNaN
            else{
                return (Int(self.x),Int(self.y))
            }
            return (Int(leftOperand),Int(rightOperand))
        }
    }
    
    ///実際のビデオのサイズと端末の表示サイズ比の縮尺
    open static var scale:(x:CGFloat,y:CGFloat) = (0,0)
    
    ///initializer
    convenience required public init?(map: Map) {
        self.init()
        self.mapping(map: map)
    }
    
    
    /// jsonからのコンバート
    ///
    /// - Parameter map: mappingデータを保持
    open  func mapping(map: Map) {
        uid <- map["uid"]
        itemIdInt <- map["iid"]
        size <- map["size"]
        x <- map["x"]
        y <- map["y"]
        z <- map["z"]
    }
}
