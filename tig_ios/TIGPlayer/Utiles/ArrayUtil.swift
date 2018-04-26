//
//  ArrayUtil.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/06/07.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import Foundation


// MARK: - Array
extension Array where Element: Equatable {
    
    /// 要素をEとして扱う
    typealias E = Element

    /// 指定した要素リストを引き、新たに要素リストを作成
    ///
    /// - Parameter other: other
    /// - Returns:
    func subtracting(_ other: [E]) -> [E] {
        return self.flatMap { element in
            if (other.filter { $0 == element }).count == 0 {
                return element
            } else {
                return nil
            }
        }
    }

    /// 指定した要素リストを引く
    ///
    /// - Parameter other: other description
    mutating func subtract(_ other: [E]) {
        self = subtracting(other)
    }
}
