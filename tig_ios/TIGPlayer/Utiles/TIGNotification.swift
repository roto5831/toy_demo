

import Foundation

/// TIGNotification
///
/// TIGConstantsにkeyは記述されている
/// @ACCESS_PUBLIC
public final class TIGNotification {

    /// 監視者が保持されるコンテナー
    private final class ObserverContainer {
        
        /// 通知名
        let name: Notification.Name
        
        /// 監視者
        let observer: NSObjectProtocol

        /// initializer
        ///
        /// - Parameters:
        ///   - name: name
        ///   - object: object
        ///   - queue: queue
        ///   - block: block
        init(name: Notification.Name, object: Any?, queue: OperationQueue?, block: @escaping (_ notification: Notification) -> Void) {
            self.name = name
            self.observer = NotificationCenter.default.addObserver(
                forName: name,
                object: object,
                queue: queue,
                using: block
            )
        }
        
        /// deinitializer
        deinit {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /// 0-N個の監視者コンテナーが保持されるプール
    private var pool = [ObserverContainer]()

    /// initializer
    public init() {}
    
    
    /// 通知を投稿する
    ///
    /// - Parameters:
    ///   - name: name
    ///   - object: object
    ///   - payload: payload
    public static func post(_ name: Notification.Name, from object: Any? = nil, payload: Any? = nil) {
        NotificationCenter.default.post(
            name: name,
            object: object,
            userInfo: payload.map { [TIGNotification.payload: $0] }
        )
    }

    /// 通知を監視する
    ///
    /// - Parameters:
    ///   - name: name
    ///   - object: object
    ///   - queue: queue
    ///   - block: block
    public func observe(_ name: Notification.Name, from object: Any? = nil, queue: OperationQueue? = nil, block: @escaping (_ notification: Notification) -> Void) {
        addToPool(name, object: object, queue: queue, block: block)
    }

    /// 通知を監視する
    ///
    /// - Parameters:
    ///   - name: name
    ///   - object: object
    ///   - queue: queue
    ///   - block: block
    public func observe<T>(_ name: Notification.Name, from object: Any? = nil, queue: OperationQueue? = nil, block: @escaping (_ notification: Notification, _ payload: T) -> Void) {
        addToPool(name, object: object, queue: queue) { [weak self] in
            guard let payload: T = self?.payload(from: $0) else {
                return
            }
            block($0, payload)
        }
    }

    /// 通知を監視する
    ///
    /// - Parameters:
    ///   - name: name
    ///   - object: object
    ///   - queue: queue
    ///   - block: block
    public func observe<T>(_ name: Notification.Name, from object: Any? = nil, queue: OperationQueue? = nil, block: @escaping (_ payload: T) -> Void) {
        addToPool(name, object: object, queue: queue) { [weak self] in
            guard let payload: T = self?.payload(from: $0) else {
                return
            }
            block(payload)
        }
    }

    /// keyを指定して監視者を廃棄
    ///
    /// - Parameter name: name
    public func dispose(_ name: Notification.Name) {
        removeFromPool(name)
    }

    /// 監視者を全て取り除く
    public func removeAll() {
        pool.removeAll()
    }

    // プールに追加
    private func addToPool(_ name: Notification.Name, object: Any?, queue: OperationQueue?, block: @escaping (Notification) -> Void) {
        pool.append(ObserverContainer(name: name, object: object, queue: queue, block: block))
    }

    /// プールから取り除く
    ///
    /// - Parameter name: name
    private func removeFromPool(_ name: Notification.Name) {
        pool = pool.filter { $0.name != name }
    }

    /// 積荷（パラメーターを渡したいときに使用）
    ///
    /// - Parameter notification: notification
    /// - Returns: T
    private func payload<T>(from notification: Notification) -> T? {
        return notification.userInfo?[TIGNotification.payload] as? T
    }
    
    ///deinitializer
    deinit {
        pool.removeAll()
    }
}

