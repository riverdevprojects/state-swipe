import SwiftUI

@MainActor final class GameStore: ObservableObject {
    @Published var session: Session
    @Published var bests: [String: Int]
    @Published var bestAtStart: Int
    let states: [USState]
    private let defaults: UserDefaults
    var round: Round { session.rounds[session.index] }
    var best: Int { bests[String(session.rounds.count), default: 0] }
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        // Packaged, validated data; a missing resource is a build configuration error.
        let url = Bundle.main.url(forResource: "states", withExtension: "json")!
        states = try! JSONDecoder().decode([USState].self, from: Data(contentsOf: url))
        let savedBests = (defaults.dictionary(forKey: "personalBests") as? [String: Int]) ?? [:]
        bests = savedBests
        if let data = defaults.data(forKey: "session"), let saved = try? JSONDecoder().decode(Session.self, from: data), !saved.rounds.isEmpty, saved.rounds.count <= 50, saved.rounds.indices.contains(saved.index), saved.rounds.allSatisfy({ (0...5).contains($0.revealed) && $0.hints.count == 5 }) {
            session = saved
            bestAtStart = defaults.integer(forKey: "bestAtStart")
        } else {
            session = Session(states: states, count: 5)
            bestAtStart = savedBests["5", default: 0]
        }
        save()
    }
    func start(count: Int) {
        session = Session(states: states, count: count)
        bestAtStart = best
        save()
    }
    func reveal() { session.reveal(); save() }
    func submit(_ state: USState) { session.submit(state); save() }
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
