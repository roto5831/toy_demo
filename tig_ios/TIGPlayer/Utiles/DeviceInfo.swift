//
//  DeviceInfo.swift
//  testProj
//
//

import UIKit

/// 端末情報
/// @ACCESS_OPEN
open class DeviceInfo {
    
    
    /// 縦横タイプ列挙
    ///
    /// - Landscape: Landscape
    /// - Portrait: Portrait
    public enum orientationType :String{
        case Landscape
        case Portrait
    }

    /// 縦横タイプ
    public var orientation: orientationType{
        if (UIInterfaceOrientationIsLandscape(UIApplication.shared.statusBarOrientation)){
            return .Landscape
        }
        if (UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation)){
            return .Portrait
        }
        return .Landscape
    }

    open var bounds:CGRect{
        get{
            return UIScreen.main.bounds
        }
    }
    
    /// 浮動小数点で表現されるサイズ
    open var rawSize:(width:CGFloat,height:CGFloat){
        get{
            return (UIScreen.main.bounds.width,UIScreen.main.bounds.height)
        }
    }
    
    /// 整数で表現されるサイズ
    open var size:(width:Int,height:Int){
        get{
            return (Int(UIScreen.main.bounds.width),Int(UIScreen.main.bounds.height))
        }
    }
    
    /// 3倍の解像度かどうか
    open var isThreeTimesLarger:Bool{
        get{
            return self.scale == 3.0
        }
    }
    
    /// LandScapeかどうか
    ///
    /// - Returns: Bool
    open var isLandScape:Bool{
        return orientation == .Landscape
    }
    
    /// x座標とy座標の最大値
    open var largestCordinates:(maxX:CGFloat,maxY:CGFloat){
        return (UIScreen.main.bounds.maxX,UIScreen.main.bounds.maxY)
    }
    
    /// 縮尺
    open var scale = UIScreen.main.scale
    
    /// 端末名
    open let dvName = UIDevice.current.model
    
    /// Os名
    open let OsName = UIDevice.current.systemName
    
    /// Osバージョン
    open let OsVersion = UIDevice.current.systemVersion
    
    /// 端末ID
    open let deviceID = UIDevice.modelName
    
    
    /// ipadかどうか
    open var isIpad:Bool{
        let deviceIdiom = UIScreen.main.traitCollection.userInterfaceIdiom
        switch (deviceIdiom) {
        case .pad:
            return true
        default:
            return false
        }
    }
    
    /// iPhoneXかどうか
    open var isIpohneX:Bool{
        guard #available(iOS 11.0, *),
            UIDevice().userInterfaceIdiom == .phone else {
                return false
        }
        let nativeSize = UIScreen.main.nativeBounds.size
        let (w, h) = (nativeSize.width, nativeSize.height)
        let (d1, d2): (CGFloat, CGFloat) = (1125.0, 2436.0)
        return (w == d1 && h == d2) || (w == d2 && h == d1)
    }
    
    /// initializer
    init() {
    }
}

// MARK: - 端末IDを取得するための拡張
extension UIDevice {

    class var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

}

