//
//  SQCache.swift
//  WeChat
//
//  Created by ysq on 2018/9/12.
//  Copyright © 2018年 ysq. All rights reserved.
//

import Foundation
import RealmSwift

public enum CacheError: Error {
    case cacheClassTypeError
    case noCache
}

class SQCache: NSObject {
    
//    public static let shared = SQCache()
    
    private var dataCache = NSCache<NSString, AnyObject>()
    
    private override init() {
        
    }
    
    public static func messageInfo(with chatId: Int, page: Int) -> [IMMessageModel] {
        print("realm query message page \(page)")
        let rows = 20
        var offset = 0
        var endOffset = 0
        var models: [IMMessageModel] = []
        do {
            let realm = try Realm()
            let results = realm.objects(IMMessageModel.self).filter("(sender_id = \(chatId) AND received_id = \(UserModel.sharedInstance.id)) OR (sender_id = \(UserModel.sharedInstance.id) AND received_id = \(chatId)) AND group_id = 1").sorted(byKeyPath: "msg_id", ascending: false)

            offset = page * rows
            if offset > results.count {
                return []
            }
            endOffset = offset + rows
            if endOffset > results.count {
                endOffset = results.count
            }

            for index in offset..<endOffset {
                models.append(results[index])
            }
            return models.reversed()

        } catch let error as NSError {
            print("realm query error \(error.localizedDescription)")
        }
        return []
    }
    
    public static func saveMessageInfo(with model: IMMessageModel) {
        print("save message")
        
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(model)
            }
        } catch let error as NSError {
            print("realm insert error \(error.localizedDescription)")
        }
    }
    
    public static func saveMsgListInfo(with model: MessageListModel) {
        print("save list info")
        
        do {
            let realm = try Realm()
            try realm.write {
                realm.add(model)
            }
        } catch let error as NSError {
            print("realm insert error \(error.localizedDescription)")
        }
    }
    
    public static func allMsgList() -> [MessageListModel] {
        
        do {
            let realm = try Realm()
            let results = realm.objects(MessageListModel.self).sorted(byKeyPath: "sort")
            var models = [MessageListModel]()
            for element in results {
                models.append(element)
            }
            return models
            
        } catch let error as NSError {
            print("realm insert error \(error.localizedDescription)")
        }
        return []
    }
    
    public static func delete(model: MessageListModel) {
        do {
            let realm = try Realm()
            try realm.write {
               realm.delete(model)
            }
        } catch let error as NSError {
            print("realm insert error \(error.localizedDescription)")
        }
    }
    
    public static func update(content: String, time: Int ,model: MessageListModel) {
        do {
            let realm = try Realm()
            try realm.write {
                model.content = content
                model.create_time = time
            }
        } catch let error as NSError {
            print("realm insert error \(error.localizedDescription)")
        }
    }
    
}

extension SQCache {
    
    public func setCache(key: NSString, value: AnyObject) {
        dataCache.setObject(value, forKey: key)
    }
    
    public func getCache<T: AnyObject>(key: NSString, type: T.Type) throws -> T {
        if let value = dataCache.object(forKey: key) {
            if value is T {
                return value as! T
            } else {
                throw CacheError.cacheClassTypeError
            }
        }
        throw CacheError.noCache
    }
    
    public func getCacheList<T: AnyObject>(key: NSString, type: [T].Type) throws -> [T] {
        // TODO: data 转 JSON 再转 Model
        if let value = dataCache.object(forKey: key) {
            if value is Array<T> {
                return value as! [T]
            } else {
                throw CacheError.cacheClassTypeError
            }
        }
        throw CacheError.noCache
    }
    
}
