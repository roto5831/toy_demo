//
//  BackScreenGenerator.swift
//  TIGPlayerExample
//
//  Created by hirotomo on 2017/06/20.
//  Copyright © 2017 MMizogaki. All rights reserved.
//

import Foundation
import UIKit
import TIGPlayer

/// 背景画像を生成
class BackScreenGenerator{

    
    /// viewからキャプチャー画像を撮りスクリーンショットを生成
    ///
    /// - Parameter view: view
    /// - Returns: UIImage
    static func getScreenShot(view:UIView) -> UIImage? {
        let rect = view.bounds
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        let context: CGContext = UIGraphicsGetCurrentContext()!
        view.layer.render(in: context)
        guard let capturedImage = UIGraphicsGetImageFromCurrentImageContext() else{
            UIGraphicsEndImageContext()
            return nil
        }
        UIGraphicsEndImageContext()
        return capturedImage
    }

    
    /// ぼかし画像を生成
    ///
    /// - Parameters:
    ///   - imageView: imageView
    ///   - value: kCIInputRadiusKeyの値 ※ぼかしの強度
    /// - Returns: UIImage
    static func getBluerdImage(imageView: UIImageView, value: Float) -> UIImage{
        let ciBluerdImage = self.applyGaussianBlurFilter(inputCIImage: CIImage(image:imageView.image!)!, value: value)
        let rect = CGRect(origin: imageView.bounds.origin, size: imageView.bounds.size)
        let context = CIContext(options: nil)
        let cgImage = context.createCGImage(ciBluerdImage, from: rect)
        let bluredImage = UIImage(cgImage: cgImage!)
        return bluredImage
    }

    /**
     ガウジアンFilterを適応する

     - parameter inputCIImage : 元CIICmage
     - parameter value : フィルターのかけ度合い
     - returns : ぼかし画像のサイズ
     */
    static func applyGaussianBlurFilter(inputCIImage: CIImage, value: Float) -> CIImage {

        //URL: http://stackoverflow.com/questions/12839729/correct-crop-of-cigaussianblur
        let affineClampFilter = CIFilter(name: "CIAffineClamp")
        let scale = getScaleAdjustedToDevice()
        let xform = CGAffineTransform(scaleX: scale.x, y: scale.y)
        affineClampFilter?.setValue(inputCIImage, forKey: kCIInputImageKey)
        affineClampFilter?.setValue(NSValue(cgAffineTransform: xform), forKey: "inputTransform")
        let outputAfterCalmp = affineClampFilter?.outputImage

        //ガウシンアン(ぼかし)フィルターの適応
        let filter = CIFilter(name: "CIGaussianBlur")
        filter?.setValue(outputAfterCalmp, forKey: kCIInputImageKey)
        filter?.setValue((value), forKey: kCIInputRadiusKey)
        let outputCIImage = filter?.outputImage

        guard let _outputCIImage = outputCIImage else {
            fatalError("applyGaussianBlurFilter does not work.")
        }

        return _outputCIImage

    }

    //TODO Player Projectに端末サイズからスケールを導き出す処理を作成して呼び出し
    static func getScaleAdjustedToDevice() ->(x:CGFloat,y:CGFloat){
        if deviceInfo.isThreeTimesLarger{
            return (0.333,0.333)
        }else{
            return (0.5,0.5)
        }
    }
}
