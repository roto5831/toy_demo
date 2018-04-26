//
//  ApiClient.swift
//  TIGPlayer
//
//  Created by 小林 宏知 on 2017/05/18.
//  Copyright © 2017年 MMizogaki. All rights reserved.
//

import Foundation
import Alamofire
import PromiseKit

/// ルーティング
/// @ACCESS_OPEN
open class Router{
    
    open static var workerToolHost:String{
        get{
            return  "http://54.65.218.178/"
        }
    }
    
    public struct apiHost {
        public static func getURL(path:path) -> String{
            var domain:String?
            switch path{
            case .meta:
                if TIGSDK_Config.metaDomain.isEmpty {
                    #if DEBUG
                        domain = "api-md.stg.tigmedia.jp/"
                    #else
                        domain = "api-md.tigmedia.jp/"
                    #endif
                } else {
                    domain = TIGSDK_Config.metaDomain
                }
            case .metaNext:
                if TIGSDK_Config.metaNextDomain.isEmpty {
                    #if DEBUG
                        domain = "api-mn.stg.tigmedia.jp/"
                    #else
                        domain = "api-mn.tigmedia.jp/"
                    #endif
                } else {
                    domain = TIGSDK_Config.metaNextDomain
                }
            case .contentsItem:
                if TIGSDK_Config.contentsItemDomain.isEmpty {
                    #if DEBUG
                        domain = "api-ci.stg.tigmedia.jp/"
                    #else
                        domain = "api-ci.tigmedia.jp/"
                    #endif
                } else {
                    domain = TIGSDK_Config.contentsItemDomain
                }
            case .contentsList:
                if TIGSDK_Config.contentsListDomain.isEmpty {
                    #if DEBUG
                        domain = "api-cl.stg.tigmedia.jp/"
                    #else
                        domain = "api-cl.tigmedia.jp/"
                    #endif
                } else {
                    domain = TIGSDK_Config.contentsListDomain
                }
            default:
                break
            }
            if let domain = domain{
                return "https://\(domain)"
            }else{
                #if DEBUG
                    return "https://api-cl.stg.tigmedia.jp/"
                #else
                    return "https://api-cl.tigmedia.jp/"
                #endif
            }
        }
    }
    
    public enum path:String{
        case analytics = "analytics.html"
        case meta = "meta"
        case metaNext = "meta_next"
        case contentsItem = "contents_item"
        case contentsList = "contents_list"
    }
    
    public enum param:String{
        case contentsId = "id"
        case time = "time"
        case page = "page"
    }
}

/// 通信処理
/// TODO Promise 生成と通信処理が結びついてしまっているのでお互い独立させたい。
/// @ACCESS_OPEN
open class ApiClient{
    /// request処理をpromiseでラップして返す。
    ///
    /// - Parameter url: url
    /// - Returns: promise
    open static func request(url:String) -> Promise<Any> {
        return Promise {
            fulfill, reject in
            Alamofire.request(url)
                .responseJSON(completionHandler: {
                    response in
                    
                    TIGLog.info(message:"ApiExecute")
                    TIGLog.debug(message:"URL", anyObject:url)
                    TIGLog.debug(message:"ResponseJSON", anyObject:response.result)
                    
                    switch response.result {
                    case .success(let value):
                        if response.response?.statusCode == 200 {
                            TIGLog.debug(message:"Success StatusCode", anyObject:response.response?.statusCode ?? "FailStatusCode")
                            fulfill(value)
                        }
                        break
                    case .failure(let error):
                        reject(error)
                        TIGLog.debug(message:"Fail StatusCode", anyObject:response.response?.statusCode ?? "FailStatusCode")
                        TIGLog.error(message:"API NetworkError", anyObject:error)
                        break
                    }
                })
        }
    }
    
    /// request処理をpromiseでラップして返す。
    ///
    /// - Parameter url: url
    /// - Returns: promise
    open static func request(host:String, params:Dictionary<String,String>? = nil) -> Promise<Any> {
        if let params = params{
            return ApiClient.request(url: "\(host)\(params.paramQuery)")
        }
        return ApiClient.request(url:"\(host)")
    }
    
    /**
     *
     * TIGPlayerExample内ローカルJsonデータを取得する
     *
     * 将来的に削除予定である
     *
     */
    /// Read from local JsonFile
    ///
    /// - Parameter path: localpath
    /// - Returns:  promise
    open static  func readFromLocal(path:String) -> Promise<Any> {
        return Promise {
            fulfill, reject in
            
            TIGLog.info(message:path)
            
            do {
                let data = try Data(contentsOf:Bundle.main.url(forResource:path, withExtension:"json")!,
                                    options: .alwaysMapped)
                fulfill(data)
                TIGLog.info(message:"ReadFromJsonExecute")
                TIGLog.info(message:path)
                print(String(data: data, encoding: .utf8)!)
                
            } catch let error as NSError {
                
                TIGLog.error(message:"ReadFromJsonJSON", anyObject:error)
            }
        }
    }
}

