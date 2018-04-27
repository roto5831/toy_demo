//
//  WebViewModel.swift
//  WebView
//
//  Created by 小林 宏知 on 2018/02/02.
//  Copyright © 2018年 小林 宏知. All rights reserved.
//

import Foundation
import UIKit
import WebKit

class WebViewController:UIViewController{
    
    var webView = WKWebView()
    
    let constraintsManager = ConstraintsManager()
    var urlStr:String?
    @IBOutlet weak var containerView: UIView!
    
    override func viewDidLoad() {
        self.initialize()
    }
    
    @IBAction func dismiss(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension WebViewController{
    
    func initialize(){
        let config =  WKWebViewConfiguration()
        config.applicationNameForUserAgent = "iPhone_Sega_Toys"
      self.clearCache()
        self.webView = WKWebView(frame: self.containerView.frame, configuration: config)
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.containerView.addSubview(self.webView)
        self.fullFill(child:self.webView , parent: self.containerView)
        if let urlStr = self.urlStr{
            self.loadRequest(urtStr: urlStr)
        }
        
    }
    
    func fullFill(child:UIView,parent:UIView){
        let constrains = [
            constraintsManager.create(item: child, toItem: parent, attribute: NSLayoutAttribute.top),
            constraintsManager.create(item: child, toItem: parent, attribute: NSLayoutAttribute.bottom),
            constraintsManager.create(item: child, toItem: parent, attribute: NSLayoutAttribute.leading),
            constraintsManager.create(item: child, toItem: parent, attribute: NSLayoutAttribute.trailing)
        ]
        constraintsManager.activate(constraints: constrains)
    }
    
    func loadRequest(urtStr:String){
        if let url = URL(string: urtStr){
            self.webView.load(URLRequest(url:url))
        }
    }
    
    func clearCache() {
        if #available(iOS 9.0, *) {
            let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
            let date = NSDate(timeIntervalSince1970: 0)
            WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date as Date, completionHandler:{ })
        } else {
            var libraryPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, false).first!
            libraryPath += "/Cookies"
            
            do {
                try FileManager.default.removeItem(atPath: libraryPath)
            } catch {
                print("error")
            }
            URLCache.shared.removeAllCachedResponses()
        }
    }

}

