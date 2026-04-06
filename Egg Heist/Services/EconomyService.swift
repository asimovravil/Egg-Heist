import Foundation

final class EconomyService {
    static let shared = EconomyService()
    private let storage = StorageService.shared

    func rewardForEggRescue(type: EggType, timeBonus: Bool, noDamage: Bool) -> Int {
        var base: Int
        switch type {
        case .normal: base = 10
        case .double: base = 20
        case .golden: base = 50
        case .fragile: base = 30
        }
        if timeBonus { base += 5 }
        if noDamage { base += 10 }
        return base
    }

    func addCoins(_ amount: Int) {
        storage.coins += amount
    }

    func spendCoins(_ amount: Int) -> Bool {
        guard storage.coins >= amount else { return false }
        storage.coins -= amount
        return true
    }

    func speedUpgradePrice(level: Int) -> Int {
        return 50 + level * 30
    }

    func heatResistPrice(level: Int) -> Int {
        return 60 + level * 40
    }

    var iceBurstPrice: Int { 30 }
    var extraLifePrice: Int { 40 }

    func skinPrice(_ skin: String) -> Int {
        switch skin {
        case "golden": return 200
        case "fire": return 150
        case "ice": return 150
        case "ninja": return 300
        default: return 100
        }
    }
}

enum EggType: CaseIterable {
    case normal, double, golden, fragile

    var displayName: String {
        switch self {
        case .normal: return "Egg"
        case .double: return "Double Egg"
        case .golden: return "Golden Egg"
        case .fragile: return "Fragile Egg"
        }
    }

    var timerMultiplier: Double {
        switch self {
        case .normal: return 1.0
        case .double: return 1.0
        case .golden: return 0.8
        case .fragile: return 0.6
        }
    }
}
