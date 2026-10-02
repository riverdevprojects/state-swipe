import SwiftUI
import UIKit

let ink = Color(red: 0.15, green: 0.22, blue: 0.18)
let orange = Color(red: 0.88, green: 0.36, blue: 0.21)
let paper = Color(red: 0.965, green: 0.957, blue: 0.929)

struct GameView: View {
    @EnvironmentObject var game: GameStore
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.dynamicTypeSize) var typeSize
    @State private var guess = ""
    @State private var abbreviation = ""
    @State private var bonusError = ""
    @FocusState private var bonusTyping: Bool
    @State private var error = ""
    @State private var showSettings = false
    @State private var showHelp = false
    @State private var answerVisible = false
    @State private var flash = false
    @FocusState private var typing: Bool

    private var compact: Bool { UIScreen.main.bounds.height <= 667 }

    var body: some View {
        ScrollView {
            VStack(spacing: compact ? 12 : 20) {
                header
                VStack(spacing: 18) {
                    scoreHeader
                    if game.session.finished { summary } else { play }
                }
                .padding(18).background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 23))
                .overlay(RoundedRectangle(cornerRadius: 23).stroke(ink.opacity(0.1)))
                HStack {
                    Label { VStack(alignment: .leading, spacing: 3) {
                        Text("PERSONAL BEST").font(.system(size: 9, weight: .bold)).tracking(1)
                        Text(game.best == 0 ? "No score yet" : "\(game.best.formatted()) points").font(.caption.weight(.semibold))
                    }} icon: { Image(systemName: "trophy").foregroundColor(orange) }
                    Spacer()
                    Button("\(game.session.rounds.count)-round session ↗") { showSettings = true }.font(.caption)
                }.foregroundColor(ink.opacity(0.7))
                
            }.padding(.horizontal, 18).padding(.top, 8).frame(maxWidth: 560).frame(maxWidth: .infinity)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(paper.ignoresSafeArea()).foregroundColor(ink)
        .sheet(isPresented: $showSettings) { settings }
        .fullScreenCover(isPresented: $showHelp) { TutorialView() }
        .onChange(of: game.session.index) { _ in resetInput() }
        .task(id: "\(game.session.index)-\(game.round.guess ?? "")") {
            guard game.round.guess != nil else { return }
            answerVisible = reduceMotion || game.round.points > 0
            if !answerVisible {
                do { try await Task.sleep(nanoseconds: 900_000_000) } catch { return }
                withAnimation(.easeInOut(duration: 0.3)) { answerVisible = true }
            }
            guard !reduceMotion else { return }
            for _ in 0..<3 {
                withAnimation(.easeInOut(duration: 0.3)) { flash.toggle() }
                do { try await Task.sleep(nanoseconds: 350_000_000) } catch { return }
            }
            flash = false
        }
    }
    private var header: some View {
        HStack {
            Image(systemName: "arrow.up.right.square.fill").font(.title2).foregroundColor(orange)
            Text("stateswipe.").font(.system(size: 24, weight: .bold, design: .rounded))
            Spacer()
            Button { typing = false; showHelp = true } label: { Image(systemName: "questionmark.circle").font(.title3).frame(width: 44, height: 44) }.accessibilityLabel("How to play").accessibilityIdentifier("help")
        }
    }
    private var scoreHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 5) {
                Text("ROUND").font(.system(size: 8, weight: .bold)).tracking(1)
                Text("Round \(game.session.index + 1) of \(game.session.rounds.count)").font(.caption.weight(.semibold))
                ProgressView(value: Double(game.session.finished ? game.session.rounds.count : game.session.index), total: Double(game.session.rounds.count)).tint(orange).frame(width: 85)
            }.foregroundColor(.secondary)
            Spacer()
            VStack(spacing: 2) {
                Text("TOTAL SCORE").font(.system(size: 8, weight: .bold)).tracking(1)
                Text(game.session.score.formatted()).font(.system(size: 30, weight: .semibold, design: .rounded))
            }.accessibilityElement(children: .ignore)
                .accessibilityLabel("Total score").accessibilityValue(game.session.score.formatted())
                .accessibilityIdentifier("total-score")
            Spacer()
            Button { showSettings = true } label: { Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44).background(paper, in: Circle()) }.accessibilityLabel("Session settings")
        }
    }
    private var play: some View {
        VStack(spacing: 16) {
            if game.round.guess == nil {
                VStack(spacing: 8) {
                    HStack {
                        Text("Which state am I?").font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(game.round.available) pts").font(.caption.weight(.semibold)).foregroundColor(ink.opacity(0.7))
                    }
                    HStack {
                        TextField("State name…", text: $guess)
                            .font(.system(size: 23, weight: .medium, design: .rounded))
                            .autocorrectionDisabled().textInputAutocapitalization(.words)
                            .submitLabel(.go).focused($typing).onSubmit(submit)
                            .accessibilityLabel("State name or abbreviation").accessibilityIdentifier("guess-input")
                        Button(action: submit) {
                            Image(systemName: "arrow.up.right").font(.title2).frame(width: 48, height: 48).background(orange, in: RoundedRectangle(cornerRadius: 11)).foregroundColor(.white)
                        }.accessibilityLabel("Lock in final guess").accessibilityIdentifier("submit-guess").disabled(guess.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }.padding(10).background(Color.white, in: RoundedRectangle(cornerRadius: 15))
                        .overlay(RoundedRectangle(cornerRadius: 15).stroke(typing ? orange : ink.opacity(0.2)))
                    if !error.isEmpty {
                        Text(error).font(.caption).foregroundColor(.red)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .accessibilityIdentifier("guess-error")
                    }
                }
            } else {
                result
                if answerVisible { abbreviationBonus }
            }
            HStack {
                Text("HINTS").font(.system(size: 8, weight: .bold)).tracking(1)
                Spacer()
                Text("\(game.round.revealed) / 5").font(.caption2)
            }.foregroundColor(.secondary)
            hintGrid
            if game.round.guess != nil && game.round.bonusResolved {
                Button { game.advance(); typing = false } label: {
                    HStack { Text(game.session.index + 1 == game.session.rounds.count ? "See my score" : "Next state"); Spacer(); Image(systemName: "arrow.right") }
                }.buttonStyle(RoadButton()).disabled(!answerVisible)
            }
        }
    }
    private var hintGrid: some View {
        VStack(spacing: 10) {
            if typeSize.isAccessibilitySize {
                ForEach(0..<5) { i in hint(i) }
            } else {
                ForEach(0..<2) { row in HStack(spacing: 10) { hint(row * 2); hint(row * 2 + 1) } }
                HStack { Spacer(minLength: 0); hint(4).frame(maxWidth: 210); Spacer(minLength: 0) }
            }
        }
    }
    private func hint(_ index: Int) -> some View {
        HintCard(hint: game.round.hints[index], number: index + 1,
                 revealed: index < game.round.revealed,
                 enabled: index == game.round.revealed && game.round.guess == nil,
                 compact: compact) {
            game.reveal()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }.accessibilityIdentifier("hint-\(index + 1)")
    }
    private var result: some View {
        VStack(spacing: 7) {
            Text(game.round.points > 0 ? "CORRECT" : "INCORRECT").font(.system(size: 9, weight: .bold)).tracking(1)
            if !answerVisible {
                Text(game.round.guess ?? "").font(.title2).strikethrough().foregroundColor(.red)
                    .overlay(Image(systemName: "xmark").font(.system(size: 44, weight: .heavy)).foregroundColor(.red))
            } else {
                Text(game.round.state.name).font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(flash ? .green : Color(red: 0.22, green: 0.46, blue: 0.24)).scaleEffect(flash ? 1.04 : 1)
                if game.round.points == 0 { Text("You guessed \(game.round.guess ?? "").").font(.caption).foregroundColor(.secondary) }
            }
            Text("+\(game.round.points) points").font(.subheadline.weight(.semibold))
        }.padding(18).frame(maxWidth: .infinity).background(paper, in: RoundedRectangle(cornerRadius: 15))
            .accessibilityElement(children: .combine)
    }
    private var abbreviationBonus: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Abbreviation bonus").font(.headline)
            if !game.round.bonusResolved {
                Text(game.round.points > 0
                     ? "Enter the two-letter postal code for \(game.round.state.name) to double this round to \(game.round.points * 2) points."
                     : "Try the two-letter postal code for \(game.round.state.name). This round earned 0 points; the bonus is practice.")
                    .font(.subheadline).fixedSize(horizontal: false, vertical: true)
                HStack {
                    TextField("Code", text: $abbreviation)
                        .textInputAutocapitalization(.characters).autocorrectionDisabled()
                        .font(.title2.monospaced()).focused($bonusTyping)
                        .submitLabel(.go).onSubmit(submitBonus)
                        .accessibilityLabel("Two-letter postal abbreviation")
                        .accessibilityIdentifier("bonus-input")
                    Button("Submit", action: submitBonus)
                        .font(.subheadline.weight(.semibold)).padding(12)
                        .foregroundColor(.white).background(orange, in: RoundedRectangle(cornerRadius: 10))
                        .disabled(abbreviation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("submit-bonus")
                }.padding(10).background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                if !bonusError.isEmpty {
                    Text(bonusError).font(.caption).foregroundColor(.red).accessibilityIdentifier("bonus-error")
                }
                Button("Skip bonus") { bonusTyping = false; game.skipBonus() }
                    .frame(minHeight: 44).font(.subheadline).accessibilityIdentifier("skip-bonus")
            } else {
                Text(game.round.bonusCorrect
                     ? (game.round.points > 0 ? "Correct! Double points earned." : "Correct! Nice practice.")
                     : (game.round.bonusSkipped == true ? "Bonus skipped. Your points stay the same." : "Your points stay the same."))
                    .font(.subheadline.weight(.semibold)).accessibilityIdentifier("bonus-result")
                Text("\(game.round.state.name) = \(game.round.state.abbreviation)")
                    .font(.title3.monospaced().weight(.semibold)).accessibilityIdentifier("bonus-answer")
            }
        }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
    }
    private func submitBonus() {
        guard game.submitAbbreviation(abbreviation) else {
            bonusError = "Enter exactly two letters. No bonus attempt used."
            return
        }
        bonusTyping = false
        bonusError = ""
        UINotificationFeedbackGenerator().notificationOccurred(game.round.bonusCorrect ? .success : .warning)
    }
    private var summary: some View {
        VStack(spacing: 14) {
            Image(systemName: "flag.checkered").font(.largeTitle).foregroundColor(orange)
            Text("Session complete").font(.largeTitle.bold())
            Text(game.session.score.formatted()).font(.system(size: 58, weight: .bold, design: .rounded)).foregroundColor(orange)
            Text(game.session.score > game.bestAtStart ? "New personal best!" : "Session score").font(.subheadline)
            Text("\(game.session.rounds.filter { $0.points > 0 }.count) of \(game.session.rounds.count) states guessed correctly").font(.caption).foregroundColor(.secondary)
            ForEach(Array(game.session.rounds.enumerated()), id: \.offset) { _, round in
                HStack { Image(systemName: round.points > 0 ? "checkmark.circle.fill" : "xmark.circle").foregroundColor(round.points > 0 ? .green : .red); Text(round.state.name); Spacer(); if round.bonusCorrect && round.points > 0 { Text("×2").foregroundColor(orange) }; Text("\(round.points) pts") }.font(.subheadline)
            }
            Button("Play again") { game.start(count: game.session.rounds.count); resetInput() }.buttonStyle(RoadButton())
            Button("Change number of rounds") { showSettings = true }.font(.footnote)
        }
    }
    private var settings: some View { SettingsView(count: game.session.rounds.count) { count in game.start(count: count); resetInput() } }
    private func submit() {
        guard let state = GuessMatcher.resolve(guess, states: game.states) else {
            error = "Enter a U.S. state name or abbreviation. No guess used."
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
            return
        }
        typing = false
        error = ""
        answerVisible = false
        game.submit(state)
        UINotificationFeedbackGenerator().notificationOccurred(game.round.points > 0 ? .success : .error)
    }
    private func resetInput() { guess = ""; abbreviation = ""; bonusError = ""; bonusTyping = false; error = ""; answerVisible = false; flash = false }
}
struct RoadButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(16).background(ink.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 12)).foregroundColor(.white)
    }
}
private struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State var count: Int
    let start: (Int) -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                Text("Session settings").font(.largeTitle.bold())
                Text("Choose 1–50 rounds. Each session length has its own personal best.").foregroundColor(.secondary)
                Stepper("\(count) rounds", value: $count, in: 1...50).font(.title3.weight(.semibold))
                HStack { ForEach([3,5,10,25,50], id: \.self) { value in Button("\(value)") { count = value }.frame(maxWidth: .infinity, minHeight: 44).background(count == value ? orange.opacity(0.2) : Color.white, in: RoundedRectangle(cornerRadius: 9)) } }
                Text("Starting a new session replaces the current game. Personal bests stay saved.").font(.footnote).foregroundColor(.secondary)
                Button("Start session →") { start(count); dismiss() }.buttonStyle(RoadButton())
                NavigationLink("Privacy & app information") { AppInformationView() }.font(.footnote)
                Spacer()
            }.padding(24)
            }.background(paper).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }.foregroundColor(ink)
    }
}
