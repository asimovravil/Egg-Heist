import Foundation
import SpriteKit

struct Egg {
    let type: EggType
    var row: Int
    var col: Int
    var timeRemaining: TimeInterval
    var isPickedUp: Bool = false
    var isDead: Bool = false

    init(type: EggType, row: Int, col: Int, baseTime: TimeInterval = 20.0) {
        self.type = type
        self.row = row
        self.col = col
        self.timeRemaining = baseTime * type.timerMultiplier
    }

    var emoji: String {
        switch type {
        case .normal: return "egg"
        case .double: return "egg" // rendered with x2
        case .golden: return "star.fill"
        case .fragile: return "egg"
        }
    }

    var displayColor: SKColor {
        switch type {
        case .normal: return SKColor(red: 1, green: 0.96, blue: 0.88, alpha: 1) // cream
        case .double: return SKColor(red: 1, green: 0.96, blue: 0.88, alpha: 1)
        case .golden: return SKColor(red: 1, green: 0.84, blue: 0, alpha: 1)
        case .fragile: return SKColor(red: 0.9, green: 0.85, blue: 0.85, alpha: 1)
        }
    }
}

final class EggLogic {

    static func spawnEggs(level: Int, rows: Int, cols: Int, walls: Set<GridPos>, safeZone: GridPos, playerPos: GridPos, allowedPositions: Set<GridPos>? = nil) -> [Egg] {
        let count = min(3 + level / 2, 6)
        var eggs: [Egg] = []
        var occupied: Set<GridPos> = walls
        occupied.insert(safeZone)
        occupied.insert(playerPos)
        let candidates = allowedPositions?.filter { !occupied.contains($0) } ?? []

        for _ in 0..<count {
            let type = randomEggType(level: level)
            if !candidates.isEmpty {
                let free = candidates.filter { !occupied.contains($0) }
                if let pos = free.randomElement() {
                    let baseTime = max(12.0, 25.0 - Double(level) * 1.5)
                    eggs.append(Egg(type: type, row: pos.row, col: pos.col, baseTime: baseTime))
                    occupied.insert(pos)
                }
                continue
            }

            var attempts = 0
            while attempts < 100 {
                let r = Int.random(in: 1..<rows - 1)
                let c = Int.random(in: 1..<cols - 1)
                let pos = GridPos(row: r, col: c)
                if !occupied.contains(pos) {
                    let baseTime = max(12.0, 25.0 - Double(level) * 1.5)
                    eggs.append(Egg(type: type, row: r, col: c, baseTime: baseTime))
                    occupied.insert(pos)
                    break
                }
                attempts += 1
            }
        }
        return eggs
    }

    private static func randomEggType(level: Int) -> EggType {
        let roll = Int.random(in: 0..<100)
        if level >= 5 && roll < 10 { return .golden }
        if level >= 3 && roll < 25 { return .fragile }
        if level >= 2 && roll < 40 { return .double }
        return .normal
    }

    static func throwEgg(_ egg: inout Egg, direction: Direction, walls: Set<GridPos>, rows: Int, cols: Int) {
        let newRow = egg.row + direction.dr
        let newCol = egg.col + direction.dc
        let target = GridPos(row: newRow, col: newCol)
        guard newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols && !walls.contains(target) else { return }
        egg.row = newRow
        egg.col = newCol
    }
}

struct GridPos: Hashable {
    var row: Int
    var col: Int
}

enum Direction {
    case up, down, left, right

    var dr: Int {
        switch self {
        case .up: return -1
        case .down: return 1
        case .left, .right: return 0
        }
    }

    var dc: Int {
        switch self {
        case .left: return -1
        case .right: return 1
        case .up, .down: return 0
        }
    }
}
