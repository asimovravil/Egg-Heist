import Foundation

final class MovementController {
    var playerRow: Int
    var playerCol: Int
    private let rows: Int
    private let cols: Int
    private let walls: Set<GridPos>
    var speedMultiplier: Double = 1.0
    private var moveCooldown: TimeInterval = 0
    private let baseCooldown: TimeInterval = 0.15

    init(startRow: Int, startCol: Int, rows: Int, cols: Int, walls: Set<GridPos>) {
        self.playerRow = startRow
        self.playerCol = startCol
        self.rows = rows
        self.cols = cols
        self.walls = walls
    }

    func canMove(direction: Direction) -> Bool {
        let newRow = playerRow + direction.dr
        let newCol = playerCol + direction.dc
        guard newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols else { return false }
        return !walls.contains(GridPos(row: newRow, col: newCol))
    }

    func move(direction: Direction) -> Bool {
        guard moveCooldown <= 0 && canMove(direction: direction) else { return false }
        playerRow += direction.dr
        playerCol += direction.dc
        moveCooldown = baseCooldown / speedMultiplier
        return true
    }

    func update(deltaTime: TimeInterval) {
        if moveCooldown > 0 {
            moveCooldown -= deltaTime
        }
    }

    var playerPosition: GridPos {
        GridPos(row: playerRow, col: playerCol)
    }
}
