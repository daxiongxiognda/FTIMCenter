//
//  IMDispatch.swift
//  FTIMCenter
//
//  Created by 熊坤鹏 on 2026/10/12.
//

import Foundation

/// 给 `DispatchQueue` 起一个项目内专用的别名，
/// 避免和系统/第三方类型混淆，也让调用处读起来更像"IM 模块的调度队列"。
/// 纯粹是为了可读性和语义表达——调用处看到 IMDispatch.socketQueue 就知道"这是 IM 模块的队列"，
typealias IMDispatch = DispatchQueue

extension IMDispatch {


    /// socket 连接和数据处理队列。 串行队列
    /// 负责 WebSocket 的连接、收发、断线重连等 IO 相关操作。
    /// - QoS：`.userInitiated`，用户主动触发、需要较快响应。
    static let socketQueue = DispatchQueue(
        label: "xyz.xtt.tongtong.im.socketQueue",
        qos: .userInitiated
    )

    /// channel（会话/频道）管理队列。 串行队列
    /// 负责会话列表、频道状态等逻辑的串行处理。
    static let channelQueue = DispatchQueue(
        label: "xyz.xtt.tongtong.im.channelQueue",
        qos: .userInitiated
    )

    /// 计算密集型任务队列。 串行队列
    /// 负责消息编解码、排序、过滤等耗 CPU 的处理，避免阻塞主线程。
    static let computationQueue = DispatchQueue(
        label: "xyz.xtt.tongtong.im.computationQueue",
        qos: .userInitiated
    )
    
    /**
     这是典型的按职责隔离队列的做法：

     1. socketQueue —— 保证 IO 操作串行

     WebSocket 的连接、发送、接收必须串行。如果两个线程同时写 socket，会帧错乱、数据损坏。用一个串行队列把 socket 相关操作排成一队，天然避免竞争。

     2. channelQueue —— 保证会话状态一致

     会话列表、当前频道等状态，如果多线程并发改，会出现状态不一致。串行队列保证同一时刻只有一个操作在改状态。

     3. computationQueue —— 卸载 CPU 密集任务

     消息解析（比如 Protobuf 解码）、大量消息排序、过滤，这些不该在主线程做，也不能阻塞 socket 队列（否则收发会卡）。单独开一个队列处理。

     核心价值：把"IO""状态""计算"三类任务隔离，避免互相阻塞，也避免数据竞争。
     
     */
}
