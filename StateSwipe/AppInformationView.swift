import SwiftUI

struct AppInformationView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy").font(.largeTitle.bold())
                Text("Stateswipe works entirely on your device. The app does not collect, transmit, or sell personal information. It includes no advertising, analytics, tracking, or third-party SDKs.")
                Text("Saved on this iPhone").font(.headline)
                Text("Your current game, hint rotation, and personal bests are saved locally. They may be included in your device backups according to your Apple settings. Deleting the app removes its local game data; offloading it preserves that data.")
                Text("No account required").font(.headline)
                Text("All 50 states and hints are included. An internet connection is not needed to play.")
                Text("How to play").font(.headline)
                Text("Tap the question mark on the game screen for the interactive tutorial. Choose the sliders button to start a new session with 1–50 rounds.")
                Divider()
                Text("Stateswipe \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")").font(.caption).foregroundColor(.secondary)
            }.padding(24).frame(maxWidth: 560)
        }.background(paper).foregroundColor(ink).navigationTitle("App information").navigationBarTitleDisplayMode(.inline)
    }
}
