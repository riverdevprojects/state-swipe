import Foundation

struct USState: Codable, Identifiable, Equatable {
    var id: String { abbreviation }
    let name: String
    let abbreviation: String
    let flower: String
    let capital: String
    let landmark: String
    let giveaway: String
}
struct Hint: Codable { let title: String; let text: String; let cost: Int }
struct Round: Codable {
    let state: USState
    let hints: [Hint]
    var revealed = 0
    var guess: String?
    var points = 0
    var available: Int { 1000 - hints.prefix(revealed).reduce(0) { $0 + $1.cost } }
    init(state: USState, alternate: Bool = Bool.random()) {
        self.state = state
        hints = [
            Hint(title: "A little nature", text: "My floral emblem is \(state.flower.lowercased()).", cost: 0),
            alternate
                ? Hint(title: "A small detail", text: "My postal abbreviation starts with \(state.abbreviation.prefix(1)).", cost: 90)
                : Hint(title: "A small detail", text: "My name has \(state.name.filter { $0 != " " }.count) letters\(state.name.contains(" ") ? " and two words" : "").", cost: 70),
            Hint(title: "Somewhere special", text: state.landmark, cost: 160),
            Hint(title: "Capital idea", text: "My capital is \(state.capital).", cost: 250),
            Hint(title: "The big giveaway", text: state.giveaway, cost: 350)
        ]
    }
}
struct Session: Codable {
    var rounds: [Round]
    var index = 0
    var finished = false
    var score: Int { rounds.reduce(0) { $0 + $1.points } }
    init(states: [USState], count: Int) {
        rounds = states.shuffled().prefix(max(1, min(count, states.count))).map { Round(state: $0) }
    }
    mutating func reveal() {
        guard !finished, rounds[index].guess == nil, rounds[index].revealed < 5 else { return }
        rounds[index].revealed += 1
    }
    @discardableResult mutating func submit(_ guess: USState) -> Bool {
        guard !finished, rounds[index].guess == nil else { return false }
        rounds[index].guess = guess.name
        rounds[index].points = guess == rounds[index].state ? rounds[index].available : 0
        return true
    }
    mutating func advance() {
        guard !finished, rounds[index].guess != nil else { return }
        if index + 1 == rounds.count { finished = true } else { index += 1 }
    }
}
enum GuessMatcher {
    static func normalize(_ text: String) -> String { text.lowercased().filter { $0.isASCII && $0.isLetter } }
    static func distance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        var d = Array(repeating: Array(repeating: 0, count: b.count + 1), count: a.count + 1)
        for i in 0...a.count { d[i][0] = i }
        for j in 0...b.count { d[0][j] = j }
        guard !a.isEmpty, !b.isEmpty else { return max(a.count, b.count) }
        for i in 1...a.count { for j in 1...b.count {
            d[i][j] = min(d[i-1][j] + 1, d[i][j-1] + 1, d[i-1][j-1] + (a[i-1] == b[j-1] ? 0 : 1))
            if i > 1, j > 1, a[i-1] == b[j-2], a[i-2] == b[j-1] { d[i][j] = min(d[i][j], d[i-2][j-2] + 1) }
        }}
        return d[a.count][b.count]
    }
    static func resolve(_ text: String, states: [USState]) -> USState? {
        guard text.count <= 64 else { return nil }
        let input = normalize(text)
        guard !input.isEmpty else { return nil }
        if let exact = states.first(where: { normalize($0.name) == input || $0.abbreviation.lowercased() == input }) { return exact }
        let ranked = states.map { ($0, distance(input, normalize($0.name))) }.sorted { $0.1 < $1.1 }
        guard let first = ranked.first, first.1 <= (input.count < 5 ? 1 : 2), ranked.count == 1 || first.1 < ranked[1].1 else { return nil }
        return first.0
    }
}
