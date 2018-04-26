//
//  AppDelegate.swift
//  TIGPlayerExample
//
//  Created by MMizogaki on 2017/03/01.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import TIGPlayer

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var passedContentsIdFromUrl:String? = nil
    let userDefault = UserDefaults.standard
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])
        // 初回開き
//        let dict = ["firstLaunch": true]
//        self.userDefault.register(defaults: dict)
        // チュートリアル表示
//        let dictShowTutorial = ["showTutorial": false]
//        userDefault.register(defaults: dictShowTutorial)
        
        // status bar style
//        UIApplication.shared.statusBarStyle = .lightContent
        if let contentsIds = self.userDefault.stringArray(forKey: "contentsIds"){
            contentsIds.forEach{ id in
                if let items = PersistentManager.getByPrimaryKey(Items.self, primaryKey:id){
                    for item in (items.list) {
                        PersistentManager.delete(ItemModel.self, primaryKey: "\(id)\(item.itemId)")
                    }
                    PersistentManager.delete(Items.self, primaryKey:id)
                }
            }
        }
        return true
    }
    
    
    

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        if self.userDefault.bool(forKey: "firstLaunch") || self.userDefault.bool(forKey: "showTutorial"){
            NotificationCenter.default.post(name: .playTutorial, object: self, userInfo: nil)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        let alert = NetworkAlertController.getConnectionAlert()
        if !alert.getNetworkCheck() {
            return (self.window?.rootViewController?.present(alert, animated: true, completion: nil))!
        }
        
        let storybord: UIStoryboard = UIStoryboard(name: "ContentsListViewController", bundle: nil)
        if let ctr = storybord.instantiateInitialViewController() as! ContentsListViewController! {
            if let idFromUrl = self.passedContentsIdFromUrl {
                ctr.passedContentsIdFromUrl = idFromUrl
                self.window?.rootViewController?.present(ctr, animated: true)
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        if userDefault.bool(forKey: "showTutorial") {
            userDefault.set(false, forKey: "showTutorial")
        }
    }
    
    /// URL Schemeに設定されたURLを受け取る
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        self.passedContentsIdFromUrl = url.query!.substring(from: url.query!.index(url.query!.startIndex, offsetBy: 3))
        return true
    }
    
    /// Universal linkに設定されたlinkを受け取る
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {
        if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
            print(userActivity.webpageURL!)
            if let idQueryStr:String = userActivity.webpageURL!.query{
                self.passedContentsIdFromUrl = idQueryStr.substring(from: idQueryStr.index(idQueryStr.startIndex, offsetBy: 3))
            }
        }
        return true
    }
}

