//
//  TIGPlayerThumbnail.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2016/01/16.
//  Copyright © 2016年 MMizogaki. All rights reserved.
//

import AVFoundation

/// TIGPlayerThumbnail(AVAssetから生成)
/// 現在の仕様ではサーバー側でThumbnailをあらかじめ生成しているのでこのクラスは使用していない
/// @ACCESS_PUBLIC
public struct TIGPlayerThumbnail {
    
    /// サムネイル作成が要求された時間
    public var requestedTime: CMTime
    
    /// サムネイル
    public var image: UIImage?
    
    /// サムネイル作成された時間
    public var actualTime: CMTime
    
    /// イメージ作成結果
    public var result: AVAssetImageGeneratorResult
    
    /// エラー
    public var error: Error?
}
