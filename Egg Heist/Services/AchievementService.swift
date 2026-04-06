import Foundation

struct Achievement: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String

    var isUnlocked: Bool {
        StorageService.shared.unlockedAchievements.contains(id)
    }
}

final class AchievementService {
    static let shared = AchievementService()

    let allAchievements: [Achievement] = [
        Achievement(id: "first_rescue", name: "First Rescue", description: "Save your first egg", icon: AppSymbol.egg),
        Achievement(id: "heat_runner", name: "Heat Runner", description: "Survive 60 seconds in a hot zone", icon: "flame"),
        Achievement(id: "golden_savior", name: "Golden Savior", description: "Save a golden egg", icon: "star.fill"),
        Achievement(id: "perfect_delivery", name: "Perfect Delivery", description: "Deliver 5 eggs without damage", icon: "checkmark.seal.fill"),
        Achievement(id: "master_incubator", name: "Master of Incubator", description: "Reach level 10", icon: "trophy.fill"),
        Achievement(id: "speed_demon", name: "Speed Demon", description: "Complete a level in under 15 seconds", icon: "bolt.fill"),
        Achievement(id: "ice_master", name: "Ice Master", description: "Use ice burst 20 times total", icon: "snowflake"),
        Achievement(id: "egg_hoarder", name: "Egg Hoarder", description: "Save 100 eggs total", icon: AppSymbol.egg),
        Achievement(id: "coin_collector", name: "Coin Collector", description: "Earn 1000 coins total", icon: "dollarsign.circle.fill"),
        Achievement(id: "survivor", name: "Survivor", description: "Maintain 90% heat survival rate", icon: "heart.fill"),
        Achievement(id: "rookie_rescuer", name: "Rookie Rescuer", description: "Save 25 eggs total", icon: AppSymbol.egg),
        Achievement(id: "legendary_hatchery", name: "Legendary Hatchery", description: "Save 250 eggs total", icon: AppSymbol.egg),
        Achievement(id: "road_runner", name: "Road Runner", description: "Walk 500 tiles", icon: "figure.walk"),
        Achievement(id: "marathon_chicken", name: "Marathon Chicken", description: "Walk 2000 tiles", icon: "figure.run"),
        Achievement(id: "hot_stepper", name: "Hot Stepper", description: "Survive 20 seconds in hot zone", icon: "flame.fill"),
        Achievement(id: "blazing_runner", name: "Blazing Runner", description: "Survive 180 seconds in hot zones", icon: "flame.circle.fill"),
        Achievement(id: "level_5_reached", name: "Getting Serious", description: "Reach level 5", icon: "5.circle.fill"),
        Achievement(id: "level_15_reached", name: "Labyrinth Elite", description: "Reach level 15", icon: "15.circle.fill"),
        Achievement(id: "wealthy_farmer", name: "Wealthy Farmer", description: "Earn 5000 coins total", icon: "banknote.fill"),
        Achievement(id: "consistent_player", name: "Consistent Player", description: "Play 20 games", icon: "gamecontroller.fill"),
        Achievement(id: "iron_chicken", name: "Iron Chicken", description: "Finish a level with no damage", icon: "shield.fill"),
    ]

    func checkAchievements(context: GameContext) {
        let storage = StorageService.shared

        if storage.eggsRescued >= 1 {
            storage.unlockAchievement("first_rescue")
        }
        if context.survivedHotZoneSeconds >= 60 {
            storage.unlockAchievement("heat_runner")
        }
        if context.survivedHotZoneSeconds >= 20 {
            storage.unlockAchievement("hot_stepper")
        }
        if context.survivedHotZoneSeconds >= 180 {
            storage.unlockAchievement("blazing_runner")
        }
        if context.savedGoldenEgg {
            storage.unlockAchievement("golden_savior")
        }
        if context.consecutivePerfectDeliveries >= 5 {
            storage.unlockAchievement("perfect_delivery")
        }
        if storage.highestLevel >= 10 {
            storage.unlockAchievement("master_incubator")
        }
        if storage.highestLevel >= 5 {
            storage.unlockAchievement("level_5_reached")
        }
        if storage.highestLevel >= 15 {
            storage.unlockAchievement("level_15_reached")
        }
        if context.levelTime > 0 && context.levelTime < 15 {
            storage.unlockAchievement("speed_demon")
        }
        if context.levelCompleted && context.noDamage {
            storage.unlockAchievement("iron_chicken")
        }
        if storage.totalDistance >= 500 {
            storage.unlockAchievement("road_runner")
        }
        if storage.totalDistance >= 2000 {
            storage.unlockAchievement("marathon_chicken")
        }
        if storage.eggsRescued >= 25 {
            storage.unlockAchievement("rookie_rescuer")
        }
        if storage.eggsRescued >= 100 {
            storage.unlockAchievement("egg_hoarder")
        }
        if storage.eggsRescued >= 250 {
            storage.unlockAchievement("legendary_hatchery")
        }
        if storage.coins >= 1000 {
            storage.unlockAchievement("coin_collector")
        }
        if storage.coins >= 5000 {
            storage.unlockAchievement("wealthy_farmer")
        }
        if storage.totalGamesPlayed >= 20 {
            storage.unlockAchievement("consistent_player")
        }
        if storage.heatSurvivalPercent >= 90 {
            storage.unlockAchievement("survivor")
        }
    }
}

struct GameContext {
    var survivedHotZoneSeconds: TimeInterval = 0
    var savedGoldenEgg: Bool = false
    var consecutivePerfectDeliveries: Int = 0
    var levelTime: TimeInterval = 0
    var noDamage: Bool = true
    var levelCompleted: Bool = false
}
