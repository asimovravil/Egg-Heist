import Combine
import SwiftUI

struct StatRow: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let icon: String
}

final class StatsViewModel: ObservableObject {
    @Published var stats: [StatRow] = []
    @Published var achievements: [Achievement] = []

    func load() {
        let storage = StorageService.shared
        stats = [
            StatRow(name: "Eggs Rescued", value: "\(storage.eggsRescued)", icon: AppSymbol.egg),
            StatRow(name: "Fastest Run", value: storage.fastestRun > 0 ? String(format: "%.1fs", storage.fastestRun) : "--", icon: "bolt.fill"),
            StatRow(name: "Heat Survival", value: String(format: "%.0f%%", storage.heatSurvivalPercent), icon: "flame.fill"),
            StatRow(name: "Total Distance", value: "\(storage.totalDistance)", icon: "figure.walk"),
            StatRow(name: "Golden Eggs Saved", value: "\(storage.goldenEggsSaved)", icon: "star.fill"),
            StatRow(name: "Highest Level", value: "\(storage.highestLevel)", icon: "trophy.fill"),
            StatRow(name: "Games Played", value: "\(storage.totalGamesPlayed)", icon: "gamecontroller.fill"),
            StatRow(name: "Total Coins", value: "\(storage.coins)", icon: "dollarsign.circle.fill"),
        ]

        achievements = AchievementService.shared.allAchievements
    }
}
