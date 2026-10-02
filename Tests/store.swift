import Foundation

@main struct StoreChecks {
    @MainActor static func main() throws {
        let states = try JSONDecoder().decode([USState].self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
        let suite = "stateswipe-store-checks-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var checks = 0
        func check(_ value: @autoclosure () -> Bool, _ message: String) {
            checks += 1; precondition(value(), message)
        }
        let store = GameStore(defaults: defaults, states: states)
        store.start(count: 1)
        let originalHints = store.round.hints.map(\.id)
        let history = defaults.dictionary(forKey: "hintHistory") as! [String: [String]]
        let resumed = GameStore(defaults: defaults, states: states)
        check(resumed.round.hints.map(\.id) == originalHints, "Reload retains selected hints")
        check((defaults.dictionary(forKey: "hintHistory") as! [String: [String]]) == history, "Reload does not consume rotation")
        resumed.submit(resumed.round.state)
        let pending = GameStore(defaults: defaults, states: states)
        check(pending.round.points == 1000 && !pending.round.bonusResolved, "Unanswered bonus resumes")
        pending.submitAbbreviation(pending.round.state.abbreviation)
        pending.advance()
        check(pending.session.finished && pending.best == 2000, "Best includes doubled points")
        let finished = GameStore(defaults: defaults, states: states)
        check(finished.best == 2000 && finished.session.score == 2000 && finished.round.bonusResolved, "Bonus, best and completion persist")
        // Each state's rotation must work beyond the first complete pool cycle.
        defaults.removeObject(forKey: "session")
        defaults.removeObject(forKey: "hintHistory")
        let rotating = GameStore(defaults: defaults, states: [states[0]])
        var previous = rotating.round.hints.map(\.id)
        var cycleIDs: [Int: Set<String>] = [:]
        // Include the initial session's selections in the cycle being checked.
        for (i, hint) in rotating.round.hints.enumerated() { cycleIDs[i] = [hint.id!] }
        for _ in 0..<25 {
            rotating.start(count: 1)
            for (i,hint) in rotating.round.hints.enumerated() {
                if !previous.isEmpty { check(previous[i] != hint.id, "No immediate repeat across cycle boundary") }
                let poolCount = states[0].hintPool!.filter { $0.difficulty == i + 1 }.count
                if cycleIDs[i, default: []].count == poolCount { cycleIDs[i] = [] }
                check(!cycleIDs[i, default: []].contains(hint.id!), "Exhaust alternatives before repetition")
                cycleIDs[i, default: []].insert(hint.id!)
            }
            previous = rotating.round.hints.map(\.id)
            let reloaded = GameStore(defaults: defaults, states: [states[0]])
            check(reloaded.round.hints.map(\.id) == previous, "Rotation survives repeated reload")
        }
        print("Passed \(checks) store checks")
    }
}
