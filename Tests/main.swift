import Foundation
let states = try JSONDecoder().decode([USState].self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
var checks = 0
func check(_ value: @autoclosure () -> Bool, _ message: String) { checks += 1; if !value() { fatalError(message) } }
check(states.count == 50, "50 states")
check(Set(states.map(\.name)).count == 50, "unique states")
let costs = [0, 90, 160, 250, 350]
for state in states {
    check(GuessMatcher.resolve(state.name, states: states) == state, "Exact name")
    check(GuessMatcher.resolve(state.abbreviation.lowercased(), states: states) == state, "Abbreviation")
    let pool = state.hintPool!
    check(pool.count >= 25, "25+ clues per state")
    check(Set(pool.compactMap(\.id)).count == pool.count, "Unique clue IDs")
    check(Set(pool.map(\.text)).count == pool.count, "Distinct clues")
    for tier in 1...5 {
        check(pool.filter { $0.difficulty == tier }.count >= 5, "Five variations at every difficulty")
    }
    check(pool.allSatisfy { $0.cost == costs[$0.difficulty! - 1] && !($0.source ?? "").isEmpty }, "Rated and sourced")
    let first = Round(state: state)
    let second = Round(state: state, recentHintIDs: first.hints.compactMap(\.id))
    check(first.hints.count == 5, "Five selected hints")
    check(zip(first.hints, first.hints.dropFirst()).allSatisfy { $0.cost < $1.cost }, "Increasing costs")
    check(zip(first.hints, second.hints).allSatisfy { $0.id != $1.id }, "Avoid consecutive repeats")
    // A full unused pool must be exhausted before any clue repeats in each tier.
    var history: [String] = []
    for _ in 0..<5 {
        let round = Round(state: state, recentHintIDs: history)
        check(round.hints.allSatisfy { !history.contains($0.id!) }, "Five visits without repeating")
        history += round.hints.compactMap(\.id)
    }
    var bonus = Session(states: [state], count: 1)
    check(!bonus.submitAbbreviation(state.abbreviation), "No bonus before state guess")
    bonus.submit(state)
    bonus.advance()
    check(!bonus.finished, "Bonus needs answer or skip before completion")
    check(!bonus.submitAbbreviation("A"), "Incomplete code does not use attempt")
    check(!bonus.submitAbbreviation("A1"), "Only ASCII letters")
    check(!bonus.submitAbbreviation("A-K"), "Punctuation not accepted")
    check(!bonus.submitAbbreviation(state.name), "State name not a postal-code bonus")
    check(bonus.submitAbbreviation(" \(state.abbreviation.lowercased()) \n"), "Trim and ignore case")
    check(bonus.score == 2000, "Double round points")
    check(!bonus.submitAbbreviation(state.abbreviation), "No bonus farming")
    let restored = try JSONDecoder().decode(Session.self, from: JSONEncoder().encode(bonus))
    check(restored.rounds[0].bonusResolved && restored.score == 2000, "Bonus persists")
    check(restored.rounds[0].hints.map(\.id) == bonus.rounds[0].hints.map(\.id), "Selected hints persist")
    bonus.skipBonus()
    check(bonus.rounds[0].bonusSkipped != true, "Cannot overwrite submitted bonus")
    bonus.advance()
    check(bonus.finished, "Bonus allows completion")
}
check(GuessMatcher.resolve("Califronia", states: states)?.name == "California", "Transposed typo")
check(GuessMatcher.resolve("Pensylvania", states: states)?.name == "Pennsylvania", "Missing letter")
check(GuessMatcher.resolve("carolina", states: states) == nil, "Ambiguous names rejected")
check(GuessMatcher.resolve("banana", states: states) == nil, "Invalid guess rejected")
check(GuessMatcher.resolve("", states: states) == nil, "Empty input")
check(GuessMatcher.resolve(String(repeating: "a", count: 10000), states: states) == nil, "Oversized paste rejected")
var trip = Session(states: states, count: 50)
check(Set(trip.rounds.map { $0.state.name }).count == 50, "No state repeats")
trip.reveal()
check(trip.rounds[0].available == 1000, "First hint free")
trip.reveal()
check(trip.rounds[0].available == 910, "Second hint cost")
let available = trip.rounds[0].available
trip.submit(trip.rounds[0].state)
check(trip.score == available, "Correct award")
check(!trip.submit(trip.rounds[1].state), "One guess only")
trip.reveal()
check(trip.rounds[0].revealed == 2, "No reveal after submission")
trip.submitAbbreviation(trip.rounds[0].state.abbreviation)
check(trip.score == available * 2, "Bonus doubles remaining points after deductions")
trip.advance()
trip.submit(trip.rounds[0].state)
check(trip.rounds[1].points == 0, "Wrong state earns zero")
trip.submitAbbreviation(trip.rounds[1].state.abbreviation)
check(trip.rounds[1].points == 0, "Bonus cannot award points for wrong state")
trip.advance()
trip.submit(trip.rounds[2].state)
trip.submitAbbreviation("ZZ")
check(trip.rounds[2].points == 1000 && trip.rounds[2].bonusResolved, "Wrong code retains score and uses attempt")
trip.advance()
trip.submit(trip.rounds[3].state)
trip.skipBonus()
check(!trip.submitAbbreviation(trip.rounds[3].state.abbreviation), "No attempt after skip")
check(trip.rounds[3].points == 1000, "Skip keeps points")
var short = Session(states: states, count: 1)
short.advance()
check(!short.finished, "Cannot skip unanswered state")
for _ in 0..<8 { short.reveal() }
check(short.rounds[0].revealed == 5, "Max five reveals")
check(short.rounds[0].available == 150, "All hints leave 150 points")
short.submit(short.rounds[0].state)
short.skipBonus()
short.advance()
check(short.finished, "Completes session")
let decoded = try JSONDecoder().decode(Session.self, from: JSONEncoder().encode(short))
check(decoded.score == short.score && decoded.finished, "Save round trip")
// Emulate a pre-update save with no bank, IDs, difficulty, or bonus fields.
var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(short)) as! [String: Any]
var rounds = legacy["rounds"] as! [[String: Any]]
for i in rounds.indices {
    rounds[i].removeValue(forKey: "abbreviationGuess"); rounds[i].removeValue(forKey: "bonusSkipped")
    var state = rounds[i]["state"] as! [String: Any]; state.removeValue(forKey: "hintPool"); rounds[i]["state"] = state
    rounds[i]["hints"] = (rounds[i]["hints"] as! [[String: Any]]).map { h -> [String: Any] in
        var old = h; old.removeValue(forKey: "id"); old.removeValue(forKey: "difficulty"); old.removeValue(forKey: "source"); return old
    }
}
legacy["rounds"] = rounds
let old = try JSONDecoder().decode(Session.self, from: JSONSerialization.data(withJSONObject: legacy))
check(old.finished && old.score == short.score, "Legacy saves keep score and completion")
check(old.rounds[0].hints[0].difficultyLabel == "Very hard", "Legacy hints display compatible rating")
print("Passed \(checks) checks; \(states.reduce(0) { $0 + $1.hintPool!.count }) bundled clues")
