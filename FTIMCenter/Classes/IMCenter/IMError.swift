//
//  IMError.swift
//  FTIMCenter
//
//  Created by 熊坤鹏 on 2026/10/12.
//

import Foundation

/// IM 模块统一错误类型。
///
/// 用于描述 IM 在连接、登录、消息处理、同步等流程中可能出现的各种错误。
/// 遵循 `Error`，可直接用于 `throws` / `catch` / `Result`。
public enum IMError: Error {

    // MARK: - 登录 / 连接状态

    /// 未登录。当前操作要求已登录，但用户尚未登录。
    case unlogin

    /// 已登录。重复登录，或当前状态不允许再次登录。
    case alreadyLogin

    /// socket 无效 / 不可用（未连接、已断开、已被释放等）。
    case invalidSocket

    // MARK: - 消息相关

    /// 消息非法（格式错误、缺少必要字段、类型不匹配等）。
    case invalidMessage

    /// JSON 解析 / 序列化失败。
    case jsonError

    // MARK: - 数据状态

    /// 空数据（查询结果为空、无可处理内容等）。
    case empty

    /// 正在同步中。同步任务尚未结束，重复触发被拒绝。
    case isSyncing

    // MARK: - 媒体相关

    /// 视频处理中（尚未就绪，无法播放 / 上传等）。
    case videoProcessing

    // MARK: - 初始化

    /// 初始化失败（配置缺失、依赖未就绪等）。
    case initError

    // MARK: - 建议补充（见下方分析）

    /// 网络不可用 / 连接失败。
    case networkUnavailable

    /// 请求超时。
    case timeout

    /// 服务端返回业务错误（携带错误码与描述）。
    case server(code: Int, message: String?)

    /// 鉴权失败（token 失效、无权限等）。
    case unauthorized

    /// 数据解析失败（非 JSON 类，如 Protobuf 解码失败）。
    case decodeFailed

    /// 操作被取消。
    case cancelled

    /// 未知错误（兜底，携带原始错误信息）。
    case unknown(Error?)
}
