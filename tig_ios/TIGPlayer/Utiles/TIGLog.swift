//
//  TIGLog.swift
//  TIGPlayer
//
//  Created by MMizogaki on 2017/05/23.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import UIKit

/**
 * Log生成者
 * FireBase Document
 * https://firebase.google.com/docs/analytics/ios/start?hl=ja
 * http://dev.classmethod.jp/smartphone/iphone/ios-firebase-analytics-start-entry/
 *
 */
/// @ACCESS_OPEN
open class TIGLog: NSObject {

    /// VerBose
    ///
    /// - Parameters:
    ///   - message: LogMessage Only DEBUG
    ///   - filename: File nema  Only DEBUG
    ///   - line:  codeLine number  Only DEBUG
    ///   - function: method name  Only DEBUG
    open class func verbose(message:String,filename: String = #file, line: Int = #line, function: String = #function) {
        #if DEBUG
        NSLog("\r Verbose:\(message)\r Filename:\((filename as NSString).lastPathComponent)\r Line:\(line)\r Func:\(function)")
        #endif
    }

    /// Debug
    ///
    /// - Parameters:
    ///   - message: LogMessage Only DEBUG
    ///   - anyObject: param  Only DEBUG
    open class  func debug(message:String,anyObject:Any) {

        #if DEBUG
        NSLog("\r Debug: \(message)\r Object: \(anyObject)")
        #endif
    }

    /// Info
    ///
    /// - Parameters:
    ///   - message: LogMessage DEBUG & RELESS
    open class func info(message:String) {

        NSLog("\r info:\(message)")
    }

    /// Error
    ///
    /// - Parameters:
    ///   - message: LogMessage DEBUG & RELESS
    ///   - anyObject: param Only DEBUG
    ///   - filename: file name Only DEBUG
    ///   - line: codeLine number  Only DEBUG
    ///   - function: method name  Only DEBUG
    open class func error(message:String,anyObject:Any,filename: String = #file, line: Int = #line, function: String = #function) {
        #if DEBUG
        NSLog("\r Error:\(message)\r Object:\(anyObject)\r Filename:\((filename as NSString).lastPathComponent)\r Line:\(line)\r Func:\(function)")
        #else
        NSLog("\r Error:\(message)")
        #endif
    }
}
