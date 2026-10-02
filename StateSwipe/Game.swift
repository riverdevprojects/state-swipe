import Foundation

struct USState: Codable, Identifiable, Equatable {
    var id: String { abbreviation }
    let name: String
    let abbreviation: String
    let flower: String
    let capital: String
    let landmark: String
    let giveaway: String
    let hintPool: [Hint]?
    static func == (lhs: USState, rhs: USState) -> Bool { lhs.id == rhs.id }
}
/// Difficulty runs from 1 (very hard/free) to 5 (giveaway/most expensive).
struct Hint: Codable {
    let title: String
    let text: String
    let cost: Int
    var id: String? = nil
    var difficulty: Int? = nil
    var source: String? = nil
    var difficultyLabel: String {
        switch difficulty ?? ([0: 1, 70: 2, 90: 2, 160: 3, 250: 4, 350: 5][cost] ?? 1) {
        case 1: return "Very hard"
        case 2: return "Hard"
        case 3: return "Medium"
        case 4: return "Easy"
        default: return "Giveaway"
        }
    }
}
struct Round: Codable {
    let state: USState
    let hints: [Hint]
    var revealed = 0
    var guess: String?
    var points = 0
    // Optional fields allow old saved sessions to load without losing progress.
    var abbreviationGuess: String?
    var bonusSkipped: Bool?
    var bonusCorrect: Bool { abbreviationGuess == state.abbreviation }
    var bonusResolved: Bool { abbreviationGuess != nil || bonusSkipped == true }
    var available: Int { 1000 - hints.prefix(revealed).reduce(0) { $0 + $1.cost } }
    init(state: USState, recentHintIDs: [String] = []) {
        self.state = state
        // Legacy sessions retain their selected hints. All new rounds use the full bank.
        let pool = state.hintPool ?? []
        var selected: [Hint] = []
        for tier in 1...5 {
            let tierPool = pool.filter { $0.difficulty == tier }
            precondition(tierPool.count >= 5, "Every state needs five hints at each difficulty")
            let options = tierPool
            let unseen = options.filter { !recentHintIDs.contains($0.id ?? "") }
            let previous = recentHintIDs.last { id in options.contains { $0.id == id } }
            selected.append((unseen.isEmpty ? options.filter { $0.id != previous } : unseen).randomElement()!)
        }
        hints = selected
    }
}
struct Session: Codable {
    var rounds: [Round]
    var index = 0
    var finished = false
    var score: Int { rounds.reduce(0) { $0 + $1.points } }
    init(states: [USState], count: Int, recentHints: [String: [String]] = [:]) {
        precondition(!states.isEmpty)
        rounds = states.shuffled().prefix(max(1, min(count, states.count))).map {
            Round(state: $0, recentHintIDs: recentHints[$0.id, default: []])
        }
    }
    mutating func reveal() {
        guard !finished, rounds[index].guess == nil, rounds[index].revealed < 5 else { return }
        rounds[index].revealed += 1
    }
    @discardableResult mutating func submit(_ guess: USState) -> Bool {
        guard !finished, rounds[index].guess == nil else { return false }
        rounds[index].guess = guess.name
        rounds[index].points = guess.id == rounds[index].state.id ? rounds[index].available : 0
        return true
    }
    /// A bonus has one attempt, accepts only two ASCII letters, and never subtracts points.
    /// Zero-point rounds still offer practice, but doubling zero cannot award points.
    @discardableResult mutating func submitAbbreviation(_ input: String) -> Bool {
        guard !finished, rounds[index].guess != nil, !rounds[index].bonusResolved else { return false }
        let code = input.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard code.count == 2, code.allSatisfy({ $0.isASCII && $0.isLetter }) else { return false }
        rounds[index].abbreviationGuess = code
        if rounds[index].bonusCorrect { rounds[index].points *= 2 }
        return true
    }
    mutating func skipBonus() {
        guard !finished, rounds[index].guess != nil, !rounds[index].bonusResolved else { return }
        rounds[index].bonusSkipped = true
    }
    mutating func advance() {
        guard !finished, rounds[index].guess != nil, rounds[index].bonusResolved else { return }
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
