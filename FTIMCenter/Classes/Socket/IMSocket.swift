//
//  IMSocket.swift
//  FTIMCenter
//
//  Created by 熊坤鹏 on 2026/10/10.
//

import RxSwift
import FTDb

// MARK: - 消息类型

/// socket 消息类型。
enum SocketMessageType: Int {
    /// 未知类型（占位，解析到不支持的类型时返回）。
    case unknown = 0
    /// 请求消息。
    case request
    /// 响应消息。
    case response
}

// MARK: - 消息协议

/// 所有 socket 消息的公共基协议。
protocol SocketMessage: AnyObject {
    /// 消息类型。
    var type: SocketMessageType { get }
    /// 序列化为可发送的二进制数据。
    func toData() throws -> Data
}

/// 请求消息。
///
/// 语义类似 HTTP 请求：带 `verb`（方法）、`path`（路径）、`headers`、`body`。
protocol SocketRequestMessage: SocketMessage {
    /// 请求 ID，用于把响应和请求配对。
    var requestId: UInt64 { get }
    /// 请求方法（如 "GET" / "POST" / 自定义动词）。
    var verb: String { get }
    /// 请求路径。
    var path: String { get }
    /// 请求头。
    var headers: [String: String] { get }
    /// 解析请求体。
    func body() throws -> IMEnvelope
}

/// 响应消息。
protocol SocketResponseMessage: SocketMessage {
    /// 对应的请求 ID。
    var requestId: UInt64 { get }
    /// 状态码（0 表示成功，非 0 表示业务错误）。
    var status: UInt32 { get }
    /// 状态描述信息。
    var msg: String { get }
    /// 响应头。
    var headers: [String: String] { get }
    /// 解析响应体。
    func body() throws -> IMEnvelope
}

// MARK: - 消息工厂

/// 消息编解码工厂：负责把二进制解析为消息对象，以及构造要发送的消息。
protocol SocketMessageFactory: AnyObject {

    /// 把收到的二进制数据解析为消息对象。
    /// - Throws: 数据非法、类型未知等解析失败时抛错。
    func parseMessage(serialized: Data) throws -> SocketMessage

    /// 构造一个请求消息。
    func createRequest(
        requestId: UInt64,
        verb: String,
        path: String,
        headers: [String],
        body: Data?
    ) -> SocketRequestMessage

    /// 构造一个响应消息。
    func createResponse(
        requestId: UInt64,
        status: UInt32,
        msg: String,
        headers: [String],
        body: Data?
    ) -> SocketResponseMessage
}

// MARK: - 连接回调

/// socket 会话事件回调。
///
/// 由 `SocketClient` 的实现类在对应时机调用；调用方（通常是 `SocketManager`）
/// 通过实现该协议来接收连接打开、收到消息、连接关闭等事件。
protocol SocketSessionDelegate: AnyObject {

    /// socket 已打开。
    func onOpened(socket: SocketClient)

    /// 收到一个请求消息（需要本地处理并回响应）。
    func onRequest(_ message: SocketRequestMessage)

    /// 收到一个响应消息（对应某个已发出的请求）。
    func onResponse(_ message: SocketResponseMessage)

    /// socket 已关闭。
    /// - Parameter error: 非 nil 表示异常关闭；nil 表示正常关闭。
    func onClosed(socket: SocketClient, error: Error?)
}

// MARK: - 通知数据

/// socket 打开通知的负载。
struct SocketOpenedNotificationData {}

/// socket 活跃通知的负载。
struct SocketActiveNotificationData {
    /// 最近活跃时间戳。
    let activeTime: Int64
}

/// socket 关闭通知的负载。
struct SocketClosedNotificationData {
    /// 关闭原因；nil 表示正常关闭。
    let error: Error?
}

/// 消息同步通知的负载。
struct MessageSyncNotificationData {
    /// 同步时间戳。
    let syncAt: Int64
}

// MARK: - Socket 客户端

/// 底层 socket 客户端抽象。
///
/// 屏蔽具体 WebSocket 实现（Starscream / 自研等），只暴露连接、
/// 断开、写数据、写 ping/pong 这些能力。
protocol SocketClient: AnyObject {

    /// 事件回调。实现类应弱引用该 delegate。
    var delegate: SocketSessionDelegate? { get set }

    /// 当前是否已连接。
    var isConnected: Bool { get }

    /// 发起连接。
    func connect()

    /// 断开连接。
    /// - Parameters:
    ///   - forceTimeout: 强制断开的超时；nil 表示不设超时。
    ///   - closeCode: WebSocket 关闭码。
    func disconnect(forceTimeout: TimeInterval?, closeCode: UInt16)

    /// 发送数据。
    func write(data: Data, completion: (() -> Void)?) throws

    /// 发送 ping 帧。
    func write(ping: Data, completion: (() -> Void)?) throws

    /// 发送 pong 帧。
    func write(pong: Data, completion: (() -> Void)?) throws
}

// MARK: - Socket 管理器

/// 高层 socket 管理器：对外提供面向业务的收发接口。
///
/// 调用方通过 `send(verb:path:envelope:headers:)` 发起一次"请求-响应"式通信，
/// 结果以 `Single<IMEnvelope>` 返回。
protocol SocketManager: AnyObject {

    /// 管理器是否已启动（不代表 socket 已连上）。
    var isRunning: Bool { get }

    /// socket 是否已打开。
    var isSocketOpen: Bool { get }

    /// 启动并连接。
    func connect()

    /// 关闭连接并停止管理器。
    func close()

    /// 发送一次请求，等待对应响应。
    ///
    /// - Note:
    ///   - 参数非法等**同步错误**通过 `throws` 抛出；
    ///   - 网络、超时、服务端错误等**运行时错误**通过返回的 `Single` 的 `error` 传递。
    ///
    /// - Returns: 收到对应响应时发出 `IMEnvelope` 的 `Single`。
    func send(
        verb: String,
        path: String,
        envelope: IMEnvelope,
        headers: [String: String]
    ) throws -> Single<IMEnvelope>
}
