import Foundation
import CoreMotion

final class MotionManager: ObservableObject {
    private let motion = CMMotionManager()
    private var timer: Timer?

    func startShakeTracking(threshold: Double = 1.2, onProgress: @escaping (Double) -> Void) {
        guard motion.isAccelerometerAvailable else { return }
        motion.accelerometerUpdateInterval = 0.1
        motion.startAccelerometerUpdates()
        var progress: Double = 0

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let data = self.motion.accelerometerData else { return }
            let magnitude = abs(data.acceleration.x) + abs(data.acceleration.y) + abs(data.acceleration.z)
            if magnitude > threshold { progress += 0.1 }
            else { progress = max(0, progress - 0.05) }
            onProgress(progress)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        motion.stopAccelerometerUpdates()
    }
}
