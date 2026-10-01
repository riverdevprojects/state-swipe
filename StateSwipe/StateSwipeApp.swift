import SwiftUI

@main struct StateSwipeApp: App {
    @StateObject private var game: GameStore
    init() {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            let suite = "com.riverdevprojects.stateswipe.ui-testing"
            let defaults = UserDefaults(suiteName: suite)!
            if !ProcessInfo.processInfo.arguments.contains("--resume-testing") {
                defaults.removePersistentDomain(forName: suite)
            }
            _game = StateObject(wrappedValue: GameStore(defaults: defaults))
        } else {
            _game = StateObject(wrappedValue: GameStore())
        }
        #else
        _game = StateObject(wrappedValue: GameStore())
        #endif
    }
    var body: some Scene { WindowGroup { GameView().environmentObject(game) } }
}
