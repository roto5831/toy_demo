//
//  TIGPlayerTransport.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2016/01/16.
//  Copyright © 2016年 MMizogaki. All rights reserved.
//

import Foundation

/// 水平方向の進捗に対する規約 Time SliderがProgressview上を移動する際に従う
/// @ACCESS_PUBLIC
public protocol TIGPlayerHorizontalPan: class {

    /// 進捗が変化しようとしている
    ///
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - value: TimeInterval
    func player(_ player: TIGPlayer ,progressWillChange value: TimeInterval)
    
    /// 進捗が変化している
    ///
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - value: TimeInterval
    func player(_ player: TIGPlayer ,progressChanging value: TimeInterval)
    
    /// 進捗が変化した
    ///
    /// - Parameters:
    ///   - player: TIGPlayer
    ///   - value: TimeInterval
    func player(_ player: TIGPlayer ,progressDidChange value: TimeInterval)
}

/// TIGPlayerWipeViewが従う規約
/// @ACCESS_PUBLIC
public protocol TIGPlayerCustomAction:class {

    /// TIGPlayer
    weak var player: TIGPlayer? { get set }
}

/// TIGPlayerWideViewが従う規約
/// @ACCESS_PUBLIC
public protocol TIGPlayerCustom: TIGPlayerDelegate,TIGPlayerCustomAction,TIGPlayerHorizontalPan {}

