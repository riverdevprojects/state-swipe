import SwiftUI

@MainActor final class GameStore: ObservableObject {
    @Published var session: Session
    @Published var bests: [String: Int]
    @Published var bestAtStart: Int
    let states: [USState]
    private var recentHints: [String: [String]]
    private let defaults: UserDefaults
    var round: Round { session.rounds[session.index] }
    var best: Int { bests[String(session.rounds.count), default: 0] }
    init(defaults: UserDefaults = .standard, states suppliedStates: [USState]? = nil) {
        self.defaults = defaults
        recentHints = defaults.dictionary(forKey: "hintHistory") as? [String: [String]] ?? [:]
        // Packaged, validated data; a missing resource is a build configuration error.
        if let suppliedStates = suppliedStates {
            states = suppliedStates
        } else {
            let url = Bundle.main.url(forResource: "states", withExtension: "json")!
            states = try! JSONDecoder().decode([USState].self, from: Data(contentsOf: url))
        }
        let savedBests = (defaults.dictionary(forKey: "personalBests") as? [String: Int]) ?? [:]
        bests = savedBests
        if let data = defaults.data(forKey: "session"), let saved = try? JSONDecoder().decode(Session.self, from: data), !saved.rounds.isEmpty, saved.rounds.count <= 50, saved.rounds.indices.contains(saved.index), saved.rounds.allSatisfy({ (0...5).contains($0.revealed) && $0.hints.count == 5 }) {
            session = saved
            bestAtStart = defaults.integer(forKey: "bestAtStart")
        } else {
            session = Session(states: states, count: 5, recentHints: recentHints)
            bestAtStart = savedBests["5", default: 0]
        }
        rememberHints()
        save()
    }
    func start(count: Int) {
        session = Session(states: states, count: count, recentHints: recentHints)
        bestAtStart = best
        rememberHints()
        save()
    }
    func reveal() { session.reveal(); save() }
    func submit(_ state: USState) { session.submit(state); save() }
    @discardableResult func submitAbbreviation(_ input: String) -> Bool {
        let accepted = session.submitAbbreviation(input); save(); return accepted
    }
    func skipBonus() { session.skipBonus(); save() }
    private func rememberHints() {
        for round in session.rounds {
            let ids = round.hints.compactMap(\.id)
            // Resuming a session must not consume its selection twice.
            if Array(recentHints[round.state.id, default: []].suffix(ids.count)) != ids {
                for hint in round.hints {
                    guard let id = hint.id, let tier = hint.difficulty else { continue }
                    let poolIDs = Set((round.state.hintPool ?? []).filter { $0.difficulty == tier }.compactMap(\.id))
                    if poolIDs.isSubset(of: Set(recentHints[round.state.id, default: []])) {
                        recentHints[round.state.id, default: []].removeAll { poolIDs.contains($0) }
                    }
                    recentHints[round.state.id, default: []].append(id)
                }
            }
        }
        defaults.set(recentHints, forKey: "hintHistory")
    }
    func advance() {
        session.advance()
        if session.finished {
            bests[String(session.rounds.count)] = max(best, session.score)
            defaults.set(bests, forKey: "personalBests")
        }
        save()
    }
    func save() {
        if let data = try? JSONEncoder().encode(session) { defaults.set(data, forKey: "session") }
        defaults.set(bestAtStart, forKey: "bestAtStart")
    }
}
