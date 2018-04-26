//
//  MetaPageManager.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/10/05.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import Foundation

protocol MetaPageManagerComplement:class{
    func pageDidChange(newPage:Int)
}

// メタデータ取得ページ管理者
// 現在秒数に相当するメタデータのページを保持する
class MetaPageManager{
    
    weak var comp:MetaPageManagerComplement?
    var currentPage = 1{
        didSet(oldPage){
            if isInDiffrentPage(page: oldPage){
                print("pageHasChanged!!:from\(oldPage)to\(currentPage)")
                comp?.pageDidChange(newPage:currentPage)
            }
        }
    }
    
    var intervel:Double = 30.0
    
    init(){
    }
    
    init(currentPage:Int){
        self.currentPage = currentPage
    }
    
    func toOtherPageIn(second:Double){
        guard second >= 0.0 else{
            return
        }
        let page = floor(second/intervel + 1)
        self.currentPage = Int(page)
    }
    
    private func isInDiffrentPage(page:Int) -> Bool{
        return currentPage != page
    }
}
