import QuartzCore
import UIKit

final class CompletionHaptics {
    private let impactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let successGenerator = UINotificationFeedbackGenerator()
    private var lastImpactTimestamp: CFTimeInterval = 0
    private var lastSuccessTimestamp: CFTimeInterval = 0

    init() {
        impactGenerator.prepare()
        successGenerator.prepare()
    }

    func triggerGestureFeedback() {
        let now = CACurrentMediaTime()
        guard now - lastImpactTimestamp > 0.08 else {
            return
        }

        impactGenerator.impactOccurred(intensity: 0.7)
        impactGenerator.prepare()
        lastImpactTimestamp = now
    }

    func triggerSettledFeedback() {
        let now = CACurrentMediaTime()
        guard now - lastSuccessTimestamp > 0.16 else {
            return
        }

        successGenerator.notificationOccurred(.success)
        successGenerator.prepare()
        lastSuccessTimestamp = now
    }
}
