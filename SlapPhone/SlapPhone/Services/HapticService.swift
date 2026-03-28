import UIKit

final class HapticService {
    private let impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator]

    init() {
        impactGenerators = [
            .light: UIImpactFeedbackGenerator(style: .light),
            .medium: UIImpactFeedbackGenerator(style: .medium),
            .heavy: UIImpactFeedbackGenerator(style: .heavy),
            .rigid: UIImpactFeedbackGenerator(style: .rigid)
        ]
        impactGenerators.values.forEach { $0.prepare() }
    }

    func impact(intensity: Float) {
        let style: UIImpactFeedbackGenerator.FeedbackStyle
        switch intensity {
        case 0..<0.3: style = .light
        case 0.3..<0.6: style = .medium
        case 0.6..<0.8: style = .heavy
        default: style = .rigid
        }

        impactGenerators[style]?.impactOccurred(intensity: CGFloat(intensity))
    }
}
