import SwiftUI
import UIKit

/// Practice owns all its state. It cannot submit guesses or alter a saved game.
struct TutorialView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @AccessibilityFocusState private var instructionFocused: Bool
    @State private var step = 0
    @State private var typedGuess = ""
    @State private var entering = false
    @State private var selectedRounds = 5
    @State private var pulse = false

    private let titles = ["Reveal a hint", "Watch the points", "Enter your guess", "Lock it in", "See your result", "Choose your rounds"]
    private let instructions = [
        "Tap the first card. Your first hint is free, so 1,000 points are still available.",
        "Tap hint 2. This clue costs 90 points. Later hints cost more; each price is shown before you tap.",
        "Tap the answer box to enter Hawaii for this practice round. In a game, type a state name or abbreviation.",
        "Tap the orange arrow to submit. You get one final guess per state; small, clear typos are corrected.",
        "Correct answers flash green and earn the points left. A wrong guess gets a red X, reveals the answer, and earns zero.",
        "Choose a session length. Your best score is saved separately for each length. Five rounds is the default."
    ]
    private let hints = [
        Hint(title: "A little nature", text: "My floral emblem is yellow hibiscus.", cost: 0),
        Hint(title: "A small detail", text: "My postal abbreviation starts with H.", cost: 90),
        Hint(title: "Somewhere special", text: "Haleakalā National Park is here.", cost: 160),
        Hint(title: "Capital idea", text: "My capital is Honolulu.", cost: 250),
        Hint(title: "The big giveaway", text: "The only U.S. state made entirely of islands.", cost: 350)
    ]
    private var revealed: Int { min(step, 2) }
    private var compact: Bool { UIScreen.main.bounds.height <= 667 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("How to play").font(.headline)
                    Text("Practice · \(step + 1) of 6").font(.caption).foregroundColor(.secondary)
                        .accessibilityIdentifier("tutorial-progress")
                }
                Spacer()
                Button { dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                    .accessibilityLabel("Close tutorial").accessibilityIdentifier("tutorial-close")
            }.padding(.horizontal, 20).padding(.top, 4)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: compact ? 12 : 20) {
                        instruction.id("instruction")
                        if step == 5 { roundsDemo } else { gameDemo }
                        if step == 4 {
                            Button { advance() } label: {
                                HStack { Text("Continue"); Spacer(); Image(systemName: "arrow.right") }
                            }.buttonStyle(RoadButton()).accessibilityIdentifier("tutorial-continue")
                        }
                    }.padding(20).frame(maxWidth: 560).frame(maxWidth: .infinity)
                }
                .onChange(of: step) { _ in proxy.scrollTo("instruction", anchor: .top) }
            }
            HStack {
                Button("Back") { move(to: step - 1) }.disabled(step == 0 || entering).frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("tutorial-back")
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<6) { i in Circle().fill(i == step ? orange : ink.opacity(0.15)).frame(width: 6, height: 6) }
                }.accessibilityHidden(true)
                Spacer()
                Button(step == 5 ? "Done" : "Skip") { dismiss() }.frame(minWidth: 44, minHeight: 44)
                    .accessibilityIdentifier("tutorial-done")
            }.font(.subheadline.weight(.semibold)).padding(.horizontal, 24)
        }
        .background(paper.ignoresSafeArea()).foregroundColor(ink)
        .task(id: step) {
            instructionFocused = true
            guard step == 4, !reduceMotion else { return }
            for _ in 0..<4 {
                withAnimation(.easeInOut(duration: 0.3)) { pulse.toggle() }
                do { try await Task.sleep(nanoseconds: 350_000_000) } catch { return }
            }
            pulse = false
        }
        .task(id: entering) {
            guard entering else { return }
            if reduceMotion { typedGuess = "Hawaii" } else {
                for character in "Hawaii" {
                    do { try await Task.sleep(nanoseconds: 110_000_000) } catch { return }
                    typedGuess.append(character)
                }
            }
            entering = false
            advance()
        }
    }
    private var instruction: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(titles[step]).font(.system(.title2, design: .rounded).weight(.bold))
            Text(instructions[step]).font(.subheadline).fixedSize(horizontal: false, vertical: true).foregroundColor(ink.opacity(0.8))
        }.frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine).accessibilityFocused($instructionFocused)
            .accessibilityIdentifier("tutorial-instruction")
    }
    private var gameDemo: some View {
        VStack(spacing: 14) {
            HStack {
                Text("PRACTICE ROUND").font(.system(size: 9, weight: .bold)).tracking(1)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(step == 4 ? "TOTAL SCORE" : "AVAILABLE").font(.system(size: 8, weight: .bold)).tracking(1)
                    Text(step < 2 ? "1,000 pts" : "910 pts").font(.headline).accessibilityIdentifier("tutorial-points")
                }
            }.foregroundColor(ink.opacity(0.7))
            if step == 4 {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill").font(.title).foregroundColor(.green)
                    Text("Hawaii").font(.system(size: 30, weight: .bold, design: .rounded)).foregroundColor(pulse ? .green : Color(red: 0.22, green: 0.46, blue: 0.24))
                    Text("+910 points").font(.subheadline.weight(.semibold))
                }.padding(16).frame(maxWidth: .infinity).background(paper, in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityElement(children: .combine).accessibilityIdentifier("tutorial-result")
            } else {
                HStack(spacing: 10) {
                    Button { typedGuess = ""; entering = true } label: {
                        Text(typedGuess.isEmpty ? "State name…" : typedGuess)
                            .font(.system(size: 23, weight: .medium, design: .rounded))
                            .foregroundColor(typedGuess.isEmpty ? .secondary : ink)
                            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                    }.buttonStyle(.plain).disabled(step != 2 || entering)
                        .accessibilityLabel("Enter Hawaii for practice").accessibilityIdentifier("tutorial-input")
                        .overlay(alignment: .trailing) { if step == 2 && !entering { TouchGuide().offset(x: -16, y: 8) } }
                    Button { advance() } label: {
                        Image(systemName: "arrow.up.right").font(.title2).frame(width: 48, height: 48)
                            .foregroundColor(.white).background(orange, in: RoundedRectangle(cornerRadius: 11))
                    }.disabled(step != 3).accessibilityLabel("Submit practice guess").accessibilityIdentifier("tutorial-submit")
                        .overlay(alignment: .bottomTrailing) { if step == 3 { TouchGuide().offset(x: 8, y: 13) } }
                }.padding(10).background(Color.white, in: RoundedRectangle(cornerRadius: 15))
                    .overlay(RoundedRectangle(cornerRadius: 15).stroke(step == 2 || step == 3 ? orange : ink.opacity(0.15)))
            }
            VStack(spacing: 10) {
                if typeSize.isAccessibilitySize {
                    ForEach(0..<5) { index in card(index) }
                } else {
                    HStack(spacing: 10) { card(0); card(1) }
                    HStack(spacing: 10) { card(2); card(3) }
                    HStack { Spacer(minLength: 0); card(4).frame(maxWidth: 190); Spacer(minLength: 0) }
                }
            }
        }.padding(16).background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).stroke(ink.opacity(0.1)))
    }
    private func card(_ index: Int) -> some View {
        HintCard(hint: hints[index], number: index + 1, revealed: index < revealed,
                 enabled: step == index && step < 2, compact: compact) { advance() }
            .frame(minHeight: typeSize.isAccessibilitySize ? 170 : nil)
            .accessibilityIdentifier("tutorial-hint-\(index + 1)")
            .overlay(alignment: .bottomTrailing) {
                if step == index && step < 2 { TouchGuide().offset(x: -12, y: -10) }
            }
    }
    private var roundsDemo: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Session settings", systemImage: "slider.horizontal.3").font(.headline)
            Text("\(selectedRounds) rounds").font(.title2.weight(.semibold)).accessibilityIdentifier("tutorial-rounds")
            HStack(spacing: 8) {
                ForEach([3, 5, 10], id: \.self) { count in
                    Button { selectedRounds = count; UIImpactFeedbackGenerator(style: .light).impactOccurred() } label: {
                        Text("\(count)").font(.headline).frame(maxWidth: .infinity, minHeight: 48)
                            .background(selectedRounds == count ? orange.opacity(0.2) : paper, in: RoundedRectangle(cornerRadius: 10))
                    }.accessibilityLabel("Practice \(count) rounds").accessibilityIdentifier("tutorial-rounds-\(count)")
                        .overlay(alignment: .bottomTrailing) { if count == 3 && selectedRounds == 5 { TouchGuide().offset(x: 5, y: 15) } }
                }
            }
            Text("In a game, open the sliders button to choose any number from 1 to 50.").font(.subheadline).foregroundColor(.secondary)
            Label("Practice does not change your game or personal best.", systemImage: "checkmark.shield").font(.footnote).foregroundColor(.secondary)
            Button("Start playing") { dismiss() }.buttonStyle(RoadButton()).accessibilityIdentifier("tutorial-finish")
        }.padding(22).background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 22))
    }
    private func advance() { move(to: min(step + 1, 5)); UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    private func move(to value: Int) {
        step = max(0, min(value, 5))
        typedGuess = step >= 3 ? "Hawaii" : ""
        pulse = false
    }
}

/// A looping fingertip and touch ripple anchored to the actual control.
/// Decorative only: touch events and accessibility go to the control beneath it.
private struct TouchGuide: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pressed = false
    var body: some View {
        ZStack(alignment: .topLeading) {
            Circle().stroke(orange, lineWidth: 2).frame(width: 29, height: 29)
                .scaleEffect(pressed ? 1.35 : 0.6).opacity(pressed ? 0.15 : 0.85)
                .offset(x: -4, y: -8)
            Image(systemName: "hand.point.up.left.fill")
                .font(.system(size: 35, weight: .medium))
                .foregroundColor(ink).shadow(color: .white, radius: 1)
                .scaleEffect(pressed ? 0.9 : 1, anchor: .topLeading)
                .offset(x: pressed ? 0 : 5, y: pressed ? 0 : 7)
        }.frame(width: 44, height: 48).allowsHitTesting(false).accessibilityHidden(true)
            .task(id: reduceMotion) {
                pressed = false
                guard !reduceMotion else { return }
                while !Task.isCancelled {
                    withAnimation(.easeInOut(duration: 0.55)) { pressed.toggle() }
                    do { try await Task.sleep(nanoseconds: 700_000_000) } catch { return }
                }
            }
    }
}
