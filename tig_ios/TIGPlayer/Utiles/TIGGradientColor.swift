//
//  TIGGradientColor.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/06/09.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

/// グラデーション
class TIGGradientColor: CAGradientLayer {

    /// グラデーションレイヤーを作成
    ///
    /// - Parameters:
    ///   - paintFrame: paintFrame 
    ///   - top: トップにグラデーションを指定するかどうか
    /// - Returns: CAGradientLayer
    class func paintColor(paintFrame:CGRect, top:Bool) -> CAGradientLayer {

        let gradient = CAGradientLayer()
        gradient.frame = paintFrame

        if top {
            gradient.colors = [
                (UIColor(red:0, green: 0, blue: 0, alpha: 0.1).cgColor),
                (UIColor(red:0, green: 0, blue: 0, alpha: 0).cgColor)]
            return gradient
        }
        gradient.colors = [
            (UIColor(red:0, green: 0, blue: 0, alpha: 0).cgColor),
            (UIColor(red:0, green: 0, blue: 0, alpha: 0.1).cgColor)]
        return gradient
    }
}
