import Foundation

nonisolated enum AppError: LocalizedError, Equatable, Sendable {
    case invalidInput(String)
    case network(String)
    case decoding(String)
    case permissionDenied
    case permissionRestricted
    case notFound(String)
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return message
        case .network(let message):
            return message
        case .decoding(let message):
            return message
        case .permissionDenied:
            return "定位权限已关闭，请在设置中允许定位后重试。"
        case .permissionRestricted:
            return "定位权限受限，无法获取当前位置。"
        case .notFound(let value):
            return "未找到 \(value) 的天气数据。"
        case .unknown(let message):
            return message
        }
    }
}
