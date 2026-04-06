import SwiftUI
import Combine
import SpriteKit

final class GameViewModel: ObservableObject {
    @Published var currentLevel: Int
    @Published var coins: Int = StorageService.shared.coins
    @Published var eggsRemaining: Int = 0
    @Published var elapsedTime: TimeInterval = 0
    @Published var iceBurstCount: Int = 0
    @Published var gameEnded: Bool = false
    @Published var eggsRescued: Int = 0
    @Published var coinsEarned: Int = 0
    @Published var showNextLevel: Bool = false
    @Published var isPaused: Bool = false

    private(set) var scene: LabyrinthScene?
    
    init(initialLevel: Int = 1) {
        self.currentLevel = max(1, initialLevel)
    }

    func createScene(size: CGSize) -> LabyrinthScene {
        let scene = LabyrinthScene(size: size)
        scene.scaleMode = .resizeFill
        scene.level = currentLevel
        scene.gameDelegate = self
        scene.isPaused = false
        self.scene = scene
        return scene
    }

    func nextLevel() {
        currentLevel += 1
        resetRunState()
    }

    func restart() {
        resetRunState()
    }

    private func resetRunState() {
        gameEnded = false
        showNextLevel = false
        eggsRescued = 0
        coinsEarned = 0
        elapsedTime = 0
        eggsRemaining = 0
    }

    var formattedTime: String {
        let seconds = Int(elapsedTime)
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}

extension GameViewModel: LabyrinthSceneDelegate {
    func gameDidEnd(eggsRescued: Int, coinsEarned: Int, context: GameContext) {
        DispatchQueue.main.async {
            self.eggsRescued = eggsRescued
            self.coinsEarned = coinsEarned
            self.gameEnded = true
            self.showNextLevel = context.levelCompleted
        }
    }

    func coinsDidChange(_ coins: Int) {
        DispatchQueue.main.async {
            self.coins = coins
        }
    }

    func eggsRemainingDidChange(_ count: Int) {
        DispatchQueue.main.async {
            self.eggsRemaining = count
        }
    }

    func timerDidChange(_ time: TimeInterval) {
        DispatchQueue.main.async {
            self.elapsedTime = time
        }
    }

    func iceBurstCountDidChange(_ count: Int) {
        DispatchQueue.main.async {
            self.iceBurstCount = count
        }
    }
}
