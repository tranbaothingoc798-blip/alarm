import Foundation
import AVFoundation
import UIKit

final class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?
    private var hapticTimer: Timer?

    func startLoop(soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.duckOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1
            player?.play()
            startHaptics()
        } catch {
            stop()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        hapticTimer?.invalidate()
        hapticTimer = nil
    }

    private func startHaptics() {
        hapticTimer?.invalidate()
        hapticTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }
}
