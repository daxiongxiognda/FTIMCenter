//
//  IMConstants.swift
//  FTIMCenter
//
//  Created by 熊坤鹏 on 2026/10/10.
//

import Foundation

// MARK: - 常量
enum IMConstants {
    
    /// IM 协议版本号。
    static let imVer = "1.0.0"
    
    /// IM WebSocket 服务地址。
    /// - Debug：
    /// - Release：
    static var IMHost: String {
        #if DEBUG
        return "wss://im-sandbox.xtt.xyz"
        #else
        return "wss://im.xtt.xyz"
        #endif
    }

}

extension Array {

    /// 将数组按指定大小切分为若干子数组。
    ///
    /// 例如将 `[1, 2, 3, 4, 5]` 按大小 2 切分，结果为 `[[1, 2], [3, 4], [5]]`。
    /// 最后一个子数组可能不足 `size` 个元素。
    ///
    /// - Parameter size: 每个子数组的最大元素个数，必须大于 0。
    /// - Returns: 切分后的二维数组；当 `size <= 0` 时返回空数组。
    func chunked(into size: Int) -> [[Element]] {
        // 防御：size 为 0 或负数时，stride 的步长非法会导致崩溃
        guard size > 0 else { return [] }

        // stride 生成每组的起始下标：0, size, 2*size, ...
        return stride(from: 0, to: count, by: size).map { start in
            // 每组的结束下标取 min(start + size, count)，避免最后一组越界
            let end = Swift.min(start + size, count)
            return Array(self[start..<end])
        }
    }
}
