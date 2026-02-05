//
//  WeatherVisuals.swift
//  weather
//

import SwiftUI

struct WeatherSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)

            content
                .weatherGlassEffect(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }
}

struct WeatherMetricRow: View {
    let systemImage: String
    let title: String
    let value: String
    let detail: String?
    let accent: Color
    let bar: Double?

    init(
        systemImage: String,
        title: String,
        value: String,
        detail: String? = nil,
        accent: Color = .white,
        bar: Double? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.value = value
        self.detail = detail
        self.accent = accent
        self.bar = bar
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(accent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer(minLength: 0)
                    Text(value)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                }

                if let detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                if let bar {
                    WeatherMiniBar(progress: bar, accent: accent)
                        .frame(height: 5)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

struct WeatherMiniBar: View {
    let progress: Double
    let accent: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(accent.opacity(0.85))
                    .frame(width: proxy.size.width * max(0, min(1, progress)))
            }
        }
        .accessibilityHidden(true)
    }
}

struct TemperatureRangeBar: View {
    let min: Double
    let max: Double
    let value: Double

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let clamped = Swift.max(min, Swift.min(max, value))
            let progress = (clamped - min) / Swift.max(0.0001, (max - min))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.50, green: 0.90, blue: 1.00).opacity(0.85),
                                Color(red: 1.00, green: 0.90, blue: 0.55).opacity(0.95),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: width)

                Circle()
                    .fill(Color.primary.opacity(0.88))
                    .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
                    .frame(width: 10, height: 10)
                    .offset(x: (width - 10) * progress)
            }
        }
        .frame(height: 8)
        .accessibilityHidden(true)
    }
}

struct HourlyChart: View {
    let times: [String]
    let temperatures: [Double]
    let pops: [Int]?

    var body: some View {
        Canvas { context, size in
            guard temperatures.count >= 2 else { return }
            let count = min(24, temperatures.count, times.count)
            let temps = Array(temperatures.prefix(count))

            let minTemp = temps.min() ?? 0
            let maxTemp = temps.max() ?? 1

            func x(_ i: Int) -> CGFloat {
                if count <= 1 { return 0 }
                return CGFloat(i) / CGFloat(count - 1) * size.width
            }

            func y(_ t: Double) -> CGFloat {
                let progress = (t - minTemp) / max(0.0001, (maxTemp - minTemp))
                return size.height * (1 - CGFloat(progress)) * 0.72 + size.height * 0.12
            }

            // Precipitation probability bars (subtle).
            if let pops, pops.count >= count {
                for i in 0..<count {
                    let p = max(0, min(100, pops[i]))
                    let h = size.height * 0.18 * CGFloat(p) / 100.0
                    let barWidth: CGFloat = max(2, size.width / CGFloat(count) * 0.65)
                    let rect = CGRect(
                        x: x(i) - barWidth / 2,
                        y: size.height - h,
                        width: barWidth,
                        height: h
                    )
                    context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(Color.primary.opacity(0.14)))
                }
            }

            // Temperature line.
            var path = Path()
            path.move(to: CGPoint(x: x(0), y: y(temps[0])))
            for i in 1..<count {
                path.addLine(to: CGPoint(x: x(i), y: y(temps[i])))
            }

            context.stroke(path, with: .color(Color.primary.opacity(0.78)), lineWidth: 2)

            // Glow.
            context.stroke(path, with: .color(Color.primary.opacity(0.12)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
        }
        .frame(height: 92)
        .accessibilityHidden(true)
    }
}

struct HourlyTicks: View {
    let hourly: HourlyForecast
    let symbolName: (_ code: Int?, _ isDay: Bool?) -> String

    var body: some View {
        let count = min(hourly.time.count, hourly.temperature2m.count)
        let indices = stride(from: 0, to: min(24, count), by: 4).map { $0 }
        let lastIdx = indices.last ?? -1

        HStack(spacing: 0) {
            ForEach(indices, id: \.self) { idx in
                VStack(spacing: 6) {
                    Text(hourLabel(hourly.time[idx]))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Image(systemName: symbolName(hourly.weatherCode?.indices.contains(idx) == true ? hourly.weatherCode?[idx] : nil, true))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)

                    Text("\(Int(hourly.temperature2m[idx].rounded()))°")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)

                    if let pops = hourly.precipitationProbability, pops.indices.contains(idx) {
                        Text("\(pops[idx])%")
                            .font(.caption2.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    } else {
                        Text(" ")
                            .font(.caption2.weight(.semibold))
                    }
                }
                .frame(maxWidth: .infinity)

                if idx != lastIdx {
                    Divider()
                        .opacity(0.25)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func hourLabel(_ iso: String) -> String {
        let value = iso.replacingOccurrences(of: "T", with: " ")
        guard value.count >= 16 else { return value }
        let start = value.index(value.startIndex, offsetBy: 11)
        let end = value.index(value.startIndex, offsetBy: 16)
        return String(value[start..<end])
    }
}

struct WeatherHighlightTile<Visual: View>: View {
    let title: String
    let value: String
    let subtitle: String?
    let accent: Color
    @ViewBuilder let visual: Visual

    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        accent: Color = .white,
        @ViewBuilder visual: () -> Visual
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.accent = accent
        self.visual = visual()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                accent.opacity(0.20),
                                Color.primary.opacity(0.03),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                visual
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
    }
}

struct WindCompass: View {
    let degrees: Double?
    let speed: Double?

    var body: some View {
        let rotation = Angle(degrees: degrees ?? 0)
        let ringProgress = min(1, max(0, (speed ?? 0) / 20.0))

        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.14), lineWidth: 3)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(Color.primary.opacity(0.62), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Image(systemName: "arrow.up")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.primary.opacity(0.88))
                .rotationEffect(rotation)

            Circle()
                .fill(Color.primary.opacity(0.88))
                .frame(width: 4, height: 4)
        }
        .accessibilityHidden(true)
    }
}

struct RingGauge: View {
    let progress: Double
    let tint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: 5)

            Circle()
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(tint.opacity(0.92), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityHidden(true)
    }
}

struct UVGauge: View {
    let progress: Double

    var body: some View {
        let p = max(0, min(1, progress))
        let gradient = AngularGradient(
            colors: [
                Color(red: 0.50, green: 0.90, blue: 1.00),
                Color(red: 0.62, green: 0.96, blue: 0.90),
                Color(red: 1.00, green: 0.90, blue: 0.55),
                Color(red: 1.00, green: 0.55, blue: 0.55),
            ],
            center: .center
        )

        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.12), lineWidth: 5)

            Circle()
                .trim(from: 0, to: p)
                .stroke(gradient, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .accessibilityHidden(true)
    }
}

struct PrecipGauge: View {
    let progress: Double
    let tint: Color

    var body: some View {
        let p = max(0, min(1, progress))

        ZStack {
            Image(systemName: "drop.fill")
                .font(.system(size: 26, weight: .semibold, design: .rounded))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.primary.opacity(0.14))

            Rectangle()
                .fill(tint.opacity(0.85))
                .frame(height: 44 * p)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .mask(
                    Image(systemName: "drop.fill")
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                )
        }
        .accessibilityHidden(true)
    }
}

struct HeroGlow: View {
    let weatherCode: Int?
    let isDay: Bool?

    var body: some View {
        let colors = glowColors(weatherCode: weatherCode, isDay: isDay)

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: colors.map { $0.opacity(0.34) },
                        center: .center,
                        startRadius: 2,
                        endRadius: 160
                    )
                )
                .blur(radius: 16)
                .frame(width: 260, height: 220)
                .offset(x: -80, y: -50)
        }
        .allowsHitTesting(false)
    }

    private func glowColors(weatherCode: Int?, isDay: Bool?) -> [Color] {
        let code = weatherCode ?? -1
        let day = isDay ?? true

        switch code {
        case 0, 1:
            return day
                ? [Color(red: 1.00, green: 0.90, blue: 0.55), Color(red: 0.50, green: 0.90, blue: 1.00)]
                : [Color(red: 0.70, green: 0.72, blue: 1.00), Color(red: 0.36, green: 0.65, blue: 1.00)]
        case 61, 63, 65, 80, 81, 82:
            return [Color(red: 0.50, green: 0.90, blue: 1.00), Color(red: 0.62, green: 0.96, blue: 0.90)]
        case 71, 73, 75, 77, 85, 86:
            return [Color(red: 0.92, green: 0.96, blue: 1.00), Color(red: 0.74, green: 0.90, blue: 1.00)]
        case 95, 96, 99:
            return [Color(red: 0.88, green: 0.72, blue: 1.00), Color(red: 0.50, green: 0.90, blue: 1.00)]
        default:
            return [Color(red: 0.50, green: 0.90, blue: 1.00), Color(red: 1.00, green: 0.90, blue: 0.55)]
        }
    }
}

struct SunPathTile: View {
    let updateTime: String
    let sunrise: String?
    let sunset: String?

    var body: some View {
        let sunriseText = sunrise ?? "—"
        let sunsetText = sunset ?? "—"
        let progress = sunProgress(updateTime: updateTime, sunrise: sunrise, sunset: sunset) ?? 0.5

        HStack(alignment: .center, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                SunArc(progress: progress)
                    .padding(9)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 3) {
                Text("日照")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("日出 \(sunriseText) · 日落 \(sunsetText)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
    }

    private func sunProgress(updateTime: String, sunrise: String?, sunset: String?) -> Double? {
        guard
            let rise = TimeOfDay(from: sunrise),
            let set = TimeOfDay(from: sunset),
            let now = TimeOfDay(from: extractTime(from: updateTime))
        else { return nil }

        let denom = max(1, set.minutes - rise.minutes)
        let p = Double(now.minutes - rise.minutes) / Double(denom)
        return min(1, max(0, p))
    }

    private func extractTime(from string: String) -> String {
        // Accept "HH:mm" or "YYYY-MM-DD HH:mm"
        if string.count >= 5, string.contains(":") {
            return String(string.suffix(5))
        }
        return string
    }

    private struct TimeOfDay {
        let minutes: Int

        init?(from input: String?) {
            guard let input else { return nil }
            let parts = input.split(separator: ":")
            guard parts.count >= 2 else { return nil }
            guard let h = Int(parts[0]), let m = Int(parts[1]) else { return nil }
            self.minutes = h * 60 + m
        }
    }
}

struct SunArc: View {
    let progress: Double

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)
            let center = CGPoint(x: rect.midX, y: rect.midY + rect.height * 0.12)
            let radius = min(rect.width, rect.height) * 0.50

            var arc = Path()
            arc.addArc(
                center: center,
                radius: radius,
                startAngle: .degrees(180),
                endAngle: .degrees(0),
                clockwise: false
            )

            context.stroke(arc, with: .color(Color.primary.opacity(0.16)), lineWidth: 3)

            let p = max(0, min(1, progress))
            let angle = Double.pi * (1 - p)
            let x = center.x + CGFloat(cos(angle)) * radius
            let y = center.y - CGFloat(sin(angle)) * radius
            let sun = Path(ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
            context.fill(sun, with: .color(Color.primary.opacity(0.86)))
            context.fill(sun, with: .color(Color.primary.opacity(0.42)))
        }
        .accessibilityHidden(true)
    }
}
