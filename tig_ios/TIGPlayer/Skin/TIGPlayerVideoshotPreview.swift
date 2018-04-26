//
//  TigPlayerVideoshotPreview.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/06/27.
//  Copyright © 2017年  All rights reserved.
//

import UIKit
import SDWebImage

/// 再生時の秒数毎の動画プレビュー(サムネイル)
/// 動画1秒毎のプレビューがverticalNumberOfImages（縦）*　horizontalNumberOfImages（横）のnumberOfImages秒分敷き詰められた画像を内包。
/// CSS Spritesのように秒数毎に巨大な画像の一部を切り替えてプレビューを生成
class TIGPlayerVideoshotPreview:UIView{
    
    /// 時間を表示するラベル
    weak var videoshotPreviewLabel: UILabel!
    /// videoshotImageViewの表示箇所を切り替えるためのWrapper
    weak var videoshotScrollPreview: UIScrollView!
    /// verticalNumberOfImages（縦）*　horizontalNumberOfImages（横）のnumberOfImages秒分敷き詰められた画像
    weak var videoshotImageView: UIImageView!
    /// numberOfImages秒毎の画像url
    var urlContext = ""
    /// 画像urlのリスト ※numberOfImages秒以上の画像では複数画像
    var imageUrls = [URL]()
    /// 画像の拡張子
    let imageExtension = "jpg"
    /// 現在秒数での画像のインデックス
    var currentImageIndex = 0
    /// プレビュー画像総数
    var numberOfImages:Int{
        get{
            return self.verticalNumberOfImages * self.horizontalNumberOfImages
        }
    }
    /// 縦のプレビュー画像数
    let verticalNumberOfImages = 10
    /// 横のプレビュー画像数
    let horizontalNumberOfImages = 10
    /// 動画の最大秒数
    var maximumLength = 0
    /// 画像がロードされたかどうか
    var loaded = false
    /// SubViewTag
    enum videoshotPreviewSubViewTag:Int{
        case scrollPreview = 0
        case previewLabel = 1
    }
    /// videoshotScrollPreviewのSubViewTag
    enum videoshotScrollSubViewTag:Int{
        case imageView = 0
    }

    override init(frame:CGRect){
        super.init(frame:frame)
        self.initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialize()
    }
    /// 初期化
    func initialize(){
        self.isHidden = true
        self.subviews.forEach { view in
            switch view.tag{
            case videoshotPreviewSubViewTag.scrollPreview.rawValue:
                self.videoshotScrollPreview = view as! UIScrollView
            case videoshotPreviewSubViewTag.previewLabel.rawValue:
                self.videoshotPreviewLabel = view as! UILabel
            default:
                break
            }
        }
        self.videoshotScrollPreview.subviews.forEach { view in
            switch view.tag{
            case videoshotScrollSubViewTag.imageView.rawValue:
                self.videoshotImageView = view as! UIImageView
            default:
                break
            }
        }
        if let currentContent = PersistentManager.getByPrimaryKey(CurrentContent.self,primaryKey:PersistentManager.PersistentCosnt.PrimaryKey.CurrentContent.rawValue){
            self.urlContext = "\(currentContent.videoShotPrev)union_thumb_"
        }
    }
    
    /// プレビュー画像をロード
    ///
    /// - Parameter timeSlider:timeSlider
    func loadVideoPrev(timeSlider: UISlider){
        guard !self.loaded else{
            self.adjsutSizesToLoadedImage()
            return
        }
        self.frame.origin.x = timeSlider.frame.origin.x
        self.loadUrls(maximumLength: Int(timeSlider.maximumValue))
        self.loaded = true
    }
    
    /// 座標を調整
    ///
    /// - Parameter frame:
    func adjustOrigionYAbove(frame:CGRect){
        self.frame.origin.y = frame.origin.y - self.frame.height
    }

    
    /// maximumLength/numberOfImages枚の画像をロード
    ///
    /// - Parameter maximumLength: maximumLength
    func loadUrls(maximumLength:Int){
        self.maximumLength = maximumLength
        let count = (maximumLength / numberOfImages) + 1

        for index in 1...count{
            let formattedIndex = String(format: "%04d", index)
            if let url = NSURL(string:"\(urlContext)\(formattedIndex).\(imageExtension)"){
                self.imageUrls.append(url as URL)
            }
        }
        
        guard self.imageUrls.count != 0 else{
            return
        }
        self.videoshotImageView.sd_setImage(with: self.imageUrls[currentImageIndex])
    }

    /// ロードした画像のサイズに基づいいてプレビューの表示幅、高さを調整
    func adjsutSizesToLoadedImage(){
        if let image = self.videoshotImageView.image{
            guard self.videoshotImageView.frame.size != CGSize(width: image.size.width, height: image.size.height) else{
                return
            }
            self.videoshotImageView.frame.size = CGSize(width: image.size.width, height: image.size.height)
            self.videoshotScrollPreview.frame.size = CGSize(width: image.size.width / CGFloat(horizontalNumberOfImages) , height: image.size.height / CGFloat(verticalNumberOfImages))
            self.videoshotPreviewLabel.frame.size.width = image.size.width / CGFloat(horizontalNumberOfImages)
            self.frame.size = CGSize(width: image.size.width / CGFloat(horizontalNumberOfImages) , height: image.size.height / CGFloat(verticalNumberOfImages) + self.videoshotPreviewLabel.frame.size.height)
        }
    }

    
    /// 画像交換
    ///
    /// - Parameter sec: 現在秒数
    func swapImage(sec:Int){
        guard self.imageUrls.count != 0 else{
            return
        }
        let indexWillBeSwapped = sec/self.numberOfImages
        guard self.currentImageIndex != indexWillBeSwapped else{
            return
        }
        guard indexWillBeSwapped + 1 <= imageUrls.count else{
            return
        }
        self.videoshotImageView.sd_setImage(with: imageUrls[indexWillBeSwapped])
        self.currentImageIndex = indexWillBeSwapped
    }

    
    /// seekbarのタッチ、移動に基づいてプレビュー画像を表示
    ///
    /// - Parameters:
    ///   - isHidden: TIGPlayerVideoshotPreview表示、非表示
    ///   - timeSlider: 現在再生されている時間のtimeSlider
    ///   - player: TIGPlayer
    func touchSeekbar(isHidden:Bool,timeSlider: UISlider,player: TIGPlayer){
        self.isHidden = isHidden
        self.loadVideoPrev(timeSlider: timeSlider)
        self.swapImage(sec: Int(timeSlider.value))
        self.videoshotPreviewLabel.text = TIGPlayerUtils.positionFormatTime(position:TimeInterval(timeSlider.value))

        let trackRect = timeSlider.convert(timeSlider.bounds, to: nil)
        let thumbRect = timeSlider.thumbRect(forBounds: timeSlider.bounds, trackRect: trackRect, value: timeSlider.value)
        var lead = thumbRect.origin.x + thumbRect.size.width/2 - self.bounds.size.width/2

        if lead < 0 {
            lead = 0
        }else if lead + self.bounds.size.width > player.computedPlayerView.bounds.width {
            lead = player.computedPlayerView.bounds.width - self.bounds.size.width
        }
        let previewFram:CGRect = CGRect(x: lead,
                                        y: self.frame.origin.y ,
                                        width: self.frame.width,
                                        height: self.frame.height)

        if !isHidden {
            UIView.animate(withDuration: 0.01, delay: 0, options: .curveEaseIn, animations: {
                () -> Void in
                self.videoshotScrollPreview.contentOffset = self.getScrollOffsetIn(sec: Int(timeSlider.value))
                self.frame = previewFram

            }, completion: {(bool:Bool) -> Void in
                return
            })
            self.frame = previewFram
        }
    }
    
    
    /// Offset　※現在秒数のプレビュー画像がスクロールビューのどの座標にいるか
    ///
    /// - Parameter sec: 現在秒数
    /// - Returns: CGPoint
    func getScrollOffsetIn(sec:Int) -> CGPoint{
        let width:Float = Float(self.videoshotImageView.frame.width / CGFloat(horizontalNumberOfImages))
        let height:Float = Float(self.videoshotImageView.frame.height / CGFloat(verticalNumberOfImages))
        let sec_x = sec%horizontalNumberOfImages
        let sec_y = sec >= 100 ? self.getTwoDigitsSec(sec: sec)/verticalNumberOfImages : sec/verticalNumberOfImages
        return CGPoint(x: CGFloat(Float(sec_x) * width), y: CGFloat(Float(sec_y) * height))
    }

    
    /// y座標計算のため0-99までの秒数にきる
    ///
    /// - Parameter sec: 現在秒数
    /// - Returns: Int
    func getTwoDigitsSec(sec:Int) ->Int{
        let endIndex = String(sec).endIndex
        var tmp = String(sec).substring(with: String(sec).index(endIndex, offsetBy: -2)..<endIndex)
        if tmp.substring(to:tmp.index(tmp.startIndex, offsetBy: 1)) == "0"{
            tmp = String(sec).substring(with: String(sec).index(endIndex, offsetBy: -1)..<endIndex)
        }
        return Int(tmp)!
    }
}
