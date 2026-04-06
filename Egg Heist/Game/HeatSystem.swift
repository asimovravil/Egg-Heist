import Foundation
import SpriteKit

struct HeatTile {
    var row: Int
    var col: Int
    var temperature: Double // 0.0 (cold) to 1.0 (lethal)

    var state: HeatState {
        if temperature < 0.4 { return .cold }
        if temperature < 0.7 { return .warm }
        if temperature < 0.9 { return .hot }
        return .lethal
    }
}

enum HeatState {
    case cold, warm, hot, lethal

    var color: SKColor {
        switch self {
        case .cold: return SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        case .warm: return SKColor(red: 0.96, green: 0.77, blue: 0.26, alpha: 1) // #F5C542
        case .hot: return SKColor(red: 1.0, green: 0.48, blue: 0.0, alpha: 1) // #FF7A00
        case .lethal: return SKColor(red: 0.9, green: 0.0, blue: 0.15, alpha: 1) // #E60026
        }
    }
}

final class HeatSystem {
    var grid: [[Double]] // temperature values
    let rows: Int
    let cols: Int
    private var heatRate: Double
    private var waveTimer: TimeInterval = 0
    private var waveInterval: TimeInterval = 8.0
    private var waveActive: Bool = false
    private var waveRow: Int = 0
    private var waveDirection: Int = 1

    init(rows: Int, cols: Int, heatRate: Double) {
        self.rows = rows
        self.cols = cols
        self.heatRate = heatRate
        self.grid = Array(repeating: Array(repeating: 0.0, count: cols), count: rows)
    }

    func temperature(at row: Int, col: Int) -> Double {
        guard row >= 0 && row < rows && col >= 0 && col < cols else { return 1.0 }
        return grid[row][col]
    }

    func heatState(at row: Int, col: Int) -> HeatState {
        let temp = temperature(at: row, col: col)
        if temp < 0.4 { return .cold }
        if temp < 0.7 { return .warm }
        if temp < 0.9 { return .hot }
        return .lethal
    }

    func update(deltaTime: TimeInterval, level: Int) {
        let adjustedRate = heatRate + Double(level) * 0.002

        for r in 0..<rows {
            for c in 0..<cols {
                let noise = Double.random(in: -0.001...0.003)
                grid[r][c] = min(1.0, max(0.0, grid[r][c] + adjustedRate * deltaTime + noise))
            }
        }

        for r in 0..<rows {
            for c in 0..<cols where grid[r][c] > 0.9 {
                grid[r][c] = max(0.0, grid[r][c] - 0.06 * deltaTime)
            }
        }

        if level >= 3 {
            waveTimer += deltaTime
            if waveTimer >= waveInterval {
                waveTimer = 0
                waveActive = true
                waveRow = waveDirection > 0 ? 0 : rows - 1
                waveInterval = max(4.0, waveInterval - 0.5)
            }

            if waveActive {
                if waveRow >= 0 && waveRow < rows {
                    for c in 0..<cols {
                        grid[waveRow][c] = min(1.0, grid[waveRow][c] + 0.35)
                    }
                    waveRow += waveDirection
                } else {
                    waveActive = false
                    waveDirection *= -1
                }
            }
        }
    }

    func coolTile(row: Int, col: Int, radius: Int = 1) {
        for r in (row - radius)...(row + radius) {
            for c in (col - radius)...(col + radius) {
                guard r >= 0 && r < rows && c >= 0 && c < cols else { continue }
                grid[r][c] = max(0.0, grid[r][c] - 0.5)
            }
        }
    }

    func iceBurst(centerRow: Int, centerCol: Int) {
        coolTile(row: centerRow, col: centerCol, radius: 2)
    }

    func reset() {
        for r in 0..<rows {
            for c in 0..<cols {
                grid[r][c] = 0.0
            }
        }
        waveTimer = 0
        waveActive = false
        waveInterval = 8.0
    }
}
