//
//  TIGObjectThumbnail.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/04/26.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import SDWebImage

/// TIGObjectのサムネイル画像
class TIGObjectThumbnail: TIGObjectImage {

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.frame = frame
        self.isUserInteractionEnabled = false
    }
    
    /// item画像をローカルから取得してセット
    ///
    /// - Parameter urlString: item画像のurl
    func setImageView(urlString:String) {
        
        let array1:Array<String> = urlString.components(separatedBy:"itemId")
        let array2:Array<String> = (array1.last)!.components(separatedBy:".jpeg")
        
        var imageNamed = String()
        
        if urlString.contains("cnc0001") {
            
            imageNamed = "0002-itemId" + array2.first!
        }
        
        if urlString.contains("cnc0002") {
            
            imageNamed = "0003-itemId" + array2.first!
        }
        
        TIGLog.info(message:"TIGObjectThumbnail Local")
        TIGLog.debug(message:"ThumbnailImageName", anyObject:imageNamed)
        self.image = UIImage(named:imageNamed)
    }
    
    /// item画像をサーバーから取得してセット
    ///
    /// - Parameter urlString: item画像のurl
    func setImageViewWeb(urlString: String) {
        TIGLog.info(message:"TIGObjectThumbnail HLS")
        TIGLog.debug(message:"ThumbnailURL", anyObject:urlString)
        self.sd_setImage(with: NSURL(string:urlString)! as URL )
    }
}
