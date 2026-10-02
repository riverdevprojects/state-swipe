import SwiftUI

/// Shared by the game and its isolated practice tutorial.
struct HintCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let hint: Hint
    let number: Int
    let revealed: Bool
    let enabled: Bool
    var compact = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            FlipFaces(angle: revealed ? 180 : 0, hint: hint, number: number, enabled: enabled)
                .frame(maxWidth: .infinity, minHeight: compact ? 82 : 102)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.45), value: revealed)
        }
        .buttonStyle(HintButtonStyle()).disabled(!enabled)
        .accessibilityLabel(revealed ? "Hint \(number): \(hint.text)" : "Hint \(number), \(hint.difficultyLabel), \(hint.cost == 0 ? "free" : "costs \(hint.cost) points")")
        .accessibilityHint(enabled ? "Double tap to reveal" : revealed ? "Revealed" : "Reveal earlier hints first")
    }
}

private struct FlipFaces: View, Animatable {
    var angle: Double
    let hint: Hint
    let number: Int
    let enabled: Bool
    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }
    var body: some View {
        ZStack {
            VStack(spacing: 4) {
                Text(hint.difficultyLabel).font(.caption2).foregroundColor(.secondary)
                Text("?").font(.system(size: 30, weight: .light, design: .rounded)).foregroundColor(ink.opacity(0.6))
                HStack {
                    Text("Hint \(number)")
                    Spacer()
                    Text(hint.cost == 0 ? "FREE" : "−\(hint.cost) pts")
                }.font(.system(size: 10, weight: .medium)).foregroundColor(ink.opacity(0.7))
            }.padding(11).frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(paper, in: RoundedRectangle(cornerRadius: 13))
                .overlay(RoundedRectangle(cornerRadius: 13).stroke(ink.opacity(enabled ? 0.35 : 0.1), style: StrokeStyle(lineWidth: 1, dash: enabled ? [4, 3] : [])))
                .opacity(angle < 90 ? 1 : 0)
            VStack(spacing: 6) {
                Text(hint.title.uppercased()).font(.system(size: 8, weight: .semibold)).tracking(0.5).foregroundColor(ink.opacity(0.7))
                Text(hint.difficultyLabel).font(.caption2).foregroundColor(.secondary)
                Text(hint.text).font(.footnote).multilineTextAlignment(.center).minimumScaleFactor(0.85)
            }.padding(10).frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.91, green: 0.94, blue: 0.86), in: RoundedRectangle(cornerRadius: 13))
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(angle >= 90 ? 1 : 0)
        }.rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.4)
    }
}

private struct HintButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.foregroundColor(ink)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}
