import AVFoundation
import SwiftUI

@main
struct PetArenaApp: App {
    init() {
        // Game sounds mix with the user's music and respect the silent switch.
        try? AVAudioSession.sharedInstance().setCategory(.ambient)
    }

    var body: some Scene {
        WindowGroup {
            GameView()
                .ignoresSafeArea()
                .background(Color("LaunchBackground").ignoresSafeArea())
                .preferredColorScheme(.dark)
                .persistentSystemOverlays(.hidden)
        }
    }
}
