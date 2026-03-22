import Foundation

struct UserContext: Sendable {
    var localeIdentifier: String
    var prefersConcise: Bool
}

struct AISummary: Sendable {
    var title: String
    var details: String
}

struct AIAction: Identifiable, Sendable {
    var id: String
    var title: String
    var detail: String
}

protocol AIWeatherAssistantProviding: Sendable {
    func summarize(snapshot: WeatherSnapshot, context: UserContext) async throws -> AISummary
    func suggestActions(snapshot: WeatherSnapshot, context: UserContext) async throws -> [AIAction]
}

struct NoopAIProvider: AIWeatherAssistantProviding {
    func summarize(snapshot: WeatherSnapshot, context: UserContext) async throws -> AISummary {
        AISummary(
            title: "AI 摘要待启用",
            details: "已预留 AI 接口，后续可接入真实模型。"
        )
    }

    func suggestActions(snapshot: WeatherSnapshot, context: UserContext) async throws -> [AIAction] {
        []
    }
}
