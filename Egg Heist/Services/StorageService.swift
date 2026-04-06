import Foundation
import AudioToolbox
import StoreKit
import UIKit

final class StorageService {
    static let shared = StorageService()
    private let defaults = UserDefaults.standard

    private enum Keys {
        static let coins = "coins"
        static let eggsRescued = "eggsRescued"
        static let fastestRun = "fastestRun"
        static let heatSurvivalPercent = "heatSurvivalPercent"
        static let totalDistance = "totalDistance"
        static let goldenEggsSaved = "goldenEggsSaved"
        static let totalGamesPlayed = "totalGamesPlayed"
        static let highestLevel = "highestLevel"
        static let achievements = "achievements"
        static let ownedItems = "ownedItems"
        static let equippedSkin = "equippedSkin"
        static let speedLevel = "speedLevel"
        static let heatResistLevel = "heatResistLevel"
        static let iceBurstCount = "iceBurstCount"
        static let extraLifeCount = "extraLifeCount"
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let soundEnabled = "soundEnabled"
        static let hapticEnabled = "hapticEnabled"
    }

    var coins: Int {
        get { defaults.integer(forKey: Keys.coins) }
        set { defaults.set(newValue, forKey: Keys.coins) }
    }

    var eggsRescued: Int {
        get { defaults.integer(forKey: Keys.eggsRescued) }
        set { defaults.set(newValue, forKey: Keys.eggsRescued) }
    }

    var fastestRun: TimeInterval {
        get { defaults.double(forKey: Keys.fastestRun) }
        set {
            if newValue > 0 && (fastestRun == 0 || newValue < fastestRun) {
                defaults.set(newValue, forKey: Keys.fastestRun)
            }
        }
    }

    var heatSurvivalPercent: Double {
        get { defaults.double(forKey: Keys.heatSurvivalPercent) }
        set { defaults.set(newValue, forKey: Keys.heatSurvivalPercent) }
    }

    var totalDistance: Int {
        get { defaults.integer(forKey: Keys.totalDistance) }
        set { defaults.set(newValue, forKey: Keys.totalDistance) }
    }

    var goldenEggsSaved: Int {
        get { defaults.integer(forKey: Keys.goldenEggsSaved) }
        set { defaults.set(newValue, forKey: Keys.goldenEggsSaved) }
    }

    var totalGamesPlayed: Int {
        get { defaults.integer(forKey: Keys.totalGamesPlayed) }
        set { defaults.set(newValue, forKey: Keys.totalGamesPlayed) }
    }

    var highestLevel: Int {
        get { max(1, defaults.integer(forKey: Keys.highestLevel)) }
        set { defaults.set(max(highestLevel, newValue), forKey: Keys.highestLevel) }
    }

    var speedLevel: Int {
        get { defaults.integer(forKey: Keys.speedLevel) }
        set { defaults.set(newValue, forKey: Keys.speedLevel) }
    }

    var heatResistLevel: Int {
        get { defaults.integer(forKey: Keys.heatResistLevel) }
        set { defaults.set(newValue, forKey: Keys.heatResistLevel) }
    }

    var iceBurstCount: Int {
        get { defaults.integer(forKey: Keys.iceBurstCount) }
        set { defaults.set(newValue, forKey: Keys.iceBurstCount) }
    }

    var extraLifeCount: Int {
        get { defaults.integer(forKey: Keys.extraLifeCount) }
        set { defaults.set(newValue, forKey: Keys.extraLifeCount) }
    }

    var ownedSkins: [String] {
        get { defaults.stringArray(forKey: Keys.ownedItems) ?? ["default"] }
        set { defaults.set(newValue, forKey: Keys.ownedItems) }
    }

    var equippedSkin: String {
        get { defaults.string(forKey: Keys.equippedSkin) ?? "default" }
        set { defaults.set(newValue, forKey: Keys.equippedSkin) }
    }

    var unlockedAchievements: [String] {
        get { defaults.stringArray(forKey: Keys.achievements) ?? [] }
        set { defaults.set(newValue, forKey: Keys.achievements) }
    }

    func unlockAchievement(_ id: String) {
        var current = unlockedAchievements
        guard !current.contains(id) else { return }
        current.append(id)
        unlockedAchievements = current
    }

    var hasSeenOnboarding: Bool {
        get { defaults.bool(forKey: Keys.hasSeenOnboarding) }
        set { defaults.set(newValue, forKey: Keys.hasSeenOnboarding) }
    }

    var soundEnabled: Bool {
        get { defaults.object(forKey: Keys.soundEnabled) == nil ? true : defaults.bool(forKey: Keys.soundEnabled) }
        set { defaults.set(newValue, forKey: Keys.soundEnabled) }
    }

    var hapticEnabled: Bool {
        get { defaults.object(forKey: Keys.hapticEnabled) == nil ? true : defaults.bool(forKey: Keys.hapticEnabled) }
        set { defaults.set(newValue, forKey: Keys.hapticEnabled) }
    }
}

enum GameSFX {
    case tap
    case pickup
    case delivery
    case iceBurst
    case levelComplete
    case gameOver
    case error

    var systemSoundID: SystemSoundID {
        switch self {
        case .tap: return 1104
        case .pickup: return 1110
        case .delivery: return 1025
        case .iceBurst: return 1057
        case .levelComplete: return 1020
        case .gameOver: return 1006
        case .error: return 1053
        }
    }
}

final class GameFeedbackService {
    static let shared = GameFeedbackService()

    private init() {}

    func play(_ sfx: GameSFX) {
        guard StorageService.shared.soundEnabled else { return }
        AudioServicesPlaySystemSound(sfx.systemSoundID)
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        guard StorageService.shared.hapticEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard StorageService.shared.hapticEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

final class AppReviewService {
    static let shared = AppReviewService()

    private init() {}

    func requestReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }
        SKStoreReviewController.requestReview(in: scene)
    }
}
