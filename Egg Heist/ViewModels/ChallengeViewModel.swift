import Combine
import SwiftUI

struct Challenge: Identifiable {
    let id: String
    let name: String
    let description: String
    let icon: String
    let requirement: Int
    var progress: Int
    var isComplete: Bool { progress >= requirement }
}

final class ChallengeViewModel: ObservableObject {
    @Published var dailyChallenges: [Challenge] = []
    @Published var weeklyChallenges: [Challenge] = []

    func load() {
        let storage = StorageService.shared

        dailyChallenges = [
            Challenge(id: "daily_rescue_5", name: "Quick Rescuer", description: "Rescue 5 eggs today",
                      icon: AppSymbol.egg, requirement: 5, progress: min(5, storage.eggsRescued % 10)),
            Challenge(id: "daily_coins_50", name: "Coin Hunter", description: "Earn 50 coins",
                      icon: "dollarsign.circle.fill", requirement: 50, progress: min(50, storage.coins % 100)),
            Challenge(id: "daily_distance_100", name: "Marathon Runner", description: "Walk 100 tiles",
                      icon: "figure.walk", requirement: 100, progress: min(100, storage.totalDistance % 200)),
        ]

        weeklyChallenges = [
            Challenge(id: "weekly_rescue_50", name: "Egg Guardian", description: "Rescue 50 eggs this week",
                      icon: AppSymbol.egg, requirement: 50, progress: min(50, storage.eggsRescued % 100)),
            Challenge(id: "weekly_golden_5", name: "Gold Rush", description: "Save 5 golden eggs",
                      icon: "star.fill", requirement: 5, progress: min(5, storage.goldenEggsSaved % 10)),
            Challenge(id: "weekly_level_5", name: "Level Up", description: "Reach level 5",
                      icon: "trophy.fill", requirement: 5, progress: storage.highestLevel),
        ]
    }
}
