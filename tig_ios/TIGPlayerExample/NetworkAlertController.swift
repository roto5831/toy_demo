//
//  NetworkAlertController.swift
//  TIGPlayerExample
//
//  Created by MMizogaki on 2017/05/26.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import Foundation
import SystemConfiguration
import TIGPlayer

/// 通信アラート制御者
final class NetworkAlertController: UIAlertController {

    /// ロードされたタイミングでアクション追加
    override func viewDidLoad() {

        let yesAction = UIAlertAction(title:"OK", style:.default){
            action in
        }
        addAction(yesAction)
    }

    /// 通信失敗時に呼ばれるアラート制御者を取得
    ///
    /// - Returns: NetworkAlertController
    class func getConnectionAlert() -> NetworkAlertController {

        return NetworkAlertController(title:"インターネット未接続",
                                      message:"本アプリはインターネットに\n接続されていない状態で\n使用することは出来ません。",
                                      preferredStyle:.alert)
    }

   /// 通信チェック
   ///
   /// - Returns: Bool
   func getNetworkCheck() -> Bool {

        if NetworkAlertController.checkReachability(host_name: "google.com") {

            TIGLog.info(message:"Success Network")
            return true
        }
        TIGLog.error(message:"Failure Network", anyObject:NetworkAlertController.accessibilityActivate())
        return false
    }

    /// 接続が確立されているかどうか、通信が届くかどうかのチェック
    ///
    /// - Parameter host_name: host_name
    /// - Returns: Bool
    class func checkReachability(host_name:String)->Bool{

        let reachability = SCNetworkReachabilityCreateWithName(nil, host_name)!
        var flags = SCNetworkReachabilityFlags.connectionAutomatic
        if !SCNetworkReachabilityGetFlags(reachability, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }

}
