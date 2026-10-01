import Foundation
let states = try JSONDecoder().decode([USState].self, from: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1])))
var checks = 0
func check(_ value: @autoclosure () -> Bool, _ message: String) { checks += 1; if !value() { fatalError(message) } }
check(states.count == 50, "50 states")
check(Set(states.map(\.name)).count == 50, "unique states")
for state in states {
    check(GuessMatcher.resolve(state.name, states: states) == state, "Exact name")
    check(GuessMatcher.resolve(state.abbreviation.lowercased(), states: states) == state, "Abbreviation")
    for alternate in [true, false] {
        let round = Round(state: state, alternate: alternate)
        check(round.hints.count == 5, "Five hints")
        check(zip(round.hints, round.hints.dropFirst()).allSatisfy { $0.cost < $1.cost }, "Increasing costs")
    }
}
check(GuessMatcher.resolve("Califronia", states: states)?.name == "California", "Transposed typo")
check(GuessMatcher.resolve("Pensylvania", states: states)?.name == "Pennsylvania", "Missing letter")
check(GuessMatcher.resolve("carolina", states: states) == nil, "Ambiguous names rejected")
check(GuessMatcher.resolve("banana", states: states) == nil, "Invalid guess rejected")
check(GuessMatcher.resolve("", states: states) == nil, "Empty input")
var trip = Session(states: states, count: 50)
check(Set(trip.rounds.map { $0.state.name }).count == 50, "No repeats")
trip.reveal()
check(trip.rounds[0].available == 1000, "First hint free")
trip.reveal()
check((910...930).contains(trip.rounds[0].available), "Weighted deduction")
let available = trip.rounds[0].available
trip.submit(trip.rounds[0].state)
check(trip.score == available, "Correct award")
check(!trip.submit(trip.rounds[1].state), "One guess only")
trip.reveal()
check(trip.rounds[0].revealed == 2, "No reveal after submission")
trip.advance()
trip.submit(trip.rounds[0].state)
check(trip.rounds[1].points == 0, "Wrong guess zero")
var short = Session(states: states, count: 1)
short.advance()
check(!short.finished, "Cannot skip unanswered round")
for _ in 0..<8 { short.reveal() }
check(short.rounds[0].revealed == 5, "Max five reveals")
check(short.rounds[0].available > 0, "All hints leave points")
short.submit(short.rounds[0].state)
short.advance()
check(short.finished, "Completes session")
let decoded = try JSONDecoder().decode(Session.self, from: JSONEncoder().encode(short))
check(decoded.score == short.score && decoded.finished, "Save round trip")
check(GuessMatcher.resolve(String(repeating: "a", count: 10000), states: states) == nil, "Oversized paste rejected")
print("Passed \(checks) checks")
