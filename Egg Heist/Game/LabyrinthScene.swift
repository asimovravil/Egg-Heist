import SpriteKit

protocol LabyrinthSceneDelegate: AnyObject {
    func gameDidEnd(eggsRescued: Int, coinsEarned: Int, context: GameContext)
    func coinsDidChange(_ coins: Int)
    func eggsRemainingDidChange(_ count: Int)
    func timerDidChange(_ time: TimeInterval)
    func iceBurstCountDidChange(_ count: Int)
    func deliveryStreakDidChange(_ streak: Int)
}

final class LabyrinthScene: SKScene {

    weak var gameDelegate: LabyrinthSceneDelegate?

    var level: Int = 1
    private var gridRows: Int { min(8 + level, 14) }
    private var gridCols: Int { min(7 + level / 2, 10) }
    private var tileSize: CGFloat = 0
    private var gridOrigin: CGPoint = .zero

    private var heatSystem: HeatSystem!
    private var movementController: MovementController!
    private var walls: Set<GridPos> = []
    private var eggs: [Egg] = []
    private var safeZone: GridPos = GridPos(row: 0, col: 0)

    private var playerHasEgg: Bool = false
    private var carriedEggIndex: Int? = nil
    private var lastDirection: Direction = .right
    private var gameOver: Bool = false
    private var levelTime: TimeInterval = 0
    private var totalCoinsEarned: Int = 0
    private var totalEggsRescued: Int = 0
    private var gameContext = GameContext()
    private var perfectDeliveries: Int = 0
    private var heatResistance: Double = 0
    private var hasExtraLife: Bool = false
    private var extraLifeUsed: Bool = false

    private var tileNodes: [[SKShapeNode]] = []
    private var playerNode: SKShapeNode!
    private var eggNodes: [SKShapeNode] = []
    private var safeZoneNode: SKShapeNode!
    private var lastUpdateTime: TimeInterval = 0
    private var deliveryStreak: Int = 0

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(red: 0.063, green: 0.063, blue: 0.063, alpha: 1)
        view.isPaused = false
        isPaused = false

        let storage = StorageService.shared
        let speedLevel = storage.speedLevel
        let heatResistLevel = storage.heatResistLevel
        heatResistance = Double(heatResistLevel) * 0.1
        hasExtraLife = storage.extraLifeCount > 0

        setupGrid()
        generateMaze()
        setupHeatSystem()
        setupPlayer(speedLevel: speedLevel)
        setupSafeZone()
        spawnEggs()
        drawGrid()
        drawPlayer()
        drawEggs()
        drawSafeZone()

        emitEggsRemaining()
        gameDelegate?.iceBurstCountDidChange(storage.iceBurstCount)
        gameDelegate?.deliveryStreakDidChange(0)

        let swipeDirections: [UISwipeGestureRecognizer.Direction] = [.up, .down, .left, .right]
        for dir in swipeDirections {
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            swipe.direction = dir
            view.addGestureRecognizer(swipe)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
    }

    private func setupGrid() {
        let vw: CGFloat
        let vh: CGFloat
        if let v = view, v.bounds.width > 1, v.bounds.height > 1 {
            vw = v.bounds.width
            vh = v.bounds.height
        } else {
            vw = size.width
            vh = size.height
        }
        guard vw > 1, vh > 1 else { return }

        let padding: CGFloat = 16
        let availableWidth = vw - padding * 2
        let availableHeight = vh * 0.75
        tileSize = min(availableWidth / CGFloat(gridCols), availableHeight / CGFloat(gridRows))
        let totalWidth = tileSize * CGFloat(gridCols)
        let totalHeight = tileSize * CGFloat(gridRows)
        gridOrigin = CGPoint(
            x: (vw - totalWidth) / 2,
            y: vh - totalHeight - 60
        )
    }

    private func generateMaze() {
        walls.removeAll()
        for r in 0..<gridRows {
            for c in 0..<gridCols {
                if r == 0 || r == gridRows - 1 || c == 0 || c == gridCols - 1 {
                    walls.insert(GridPos(row: r, col: c))
                }
            }
        }
        let wallCount = (gridRows * gridCols) / (6 - min(level, 3))
        var placed = 0
        while placed < wallCount {
            let r = Int.random(in: 2..<gridRows - 2)
            let c = Int.random(in: 2..<gridCols - 2)
            let pos = GridPos(row: r, col: c)
            if r <= 2 && c <= 2 { continue }
            if !walls.contains(pos) {
                walls.insert(pos)
                placed += 1
            }
        }
        ensureConnectivity()
    }

    private func ensureConnectivity() {
        let start = GridPos(row: 1, col: 1)
        var visited: Set<GridPos> = []
        var queue: [GridPos] = [start]
        visited.insert(start)

        while !queue.isEmpty {
            let current = queue.removeFirst()
            for dir in [Direction.up, .down, .left, .right] {
                let next = GridPos(row: current.row + dir.dr, col: current.col + dir.dc)
                if next.row > 0 && next.row < gridRows - 1 && next.col > 0 && next.col < gridCols - 1
                    && !walls.contains(next) && !visited.contains(next) {
                    visited.insert(next)
                    queue.append(next)
                }
            }
        }

        for r in 1..<gridRows - 1 {
            for c in 1..<gridCols - 1 {
                let pos = GridPos(row: r, col: c)
                if !walls.contains(pos) && !visited.contains(pos) {
                    for dir in [Direction.up, .down, .left, .right] {
                        let neighbor = GridPos(row: pos.row + dir.dr, col: pos.col + dir.dc)
                        if walls.contains(neighbor) && neighbor.row > 0 && neighbor.row < gridRows - 1
                            && neighbor.col > 0 && neighbor.col < gridCols - 1 {
                            walls.remove(neighbor)
                            break
                        }
                    }
                }
            }
        }
    }

    private func setupHeatSystem() {
        let baseRate = 0.01 + Double(level) * 0.003
        heatSystem = HeatSystem(rows: gridRows, cols: gridCols, heatRate: baseRate)
    }

    private func setupPlayer(speedLevel: Int) {
        movementController = MovementController(startRow: 1, startCol: 1, rows: gridRows, cols: gridCols, walls: walls)
        movementController.speedMultiplier = 1.0 + Double(speedLevel) * 0.15
    }

    private func spawnEggs() {
        let playerPos = GridPos(row: 1, col: 1)
        let reachable = reachableWalkableCells(from: playerPos)
        eggs = EggLogic.spawnEggs(
            level: level,
            rows: gridRows,
            cols: gridCols,
            walls: walls,
            safeZone: safeZone,
            playerPos: playerPos,
            allowedPositions: reachable
        )
    }

    private func setupSafeZone() {
        let start = GridPos(row: 1, col: 1)
        let reachable = reachableWalkableCells(from: start)
        if let farthest = reachable.max(by: { lhs, rhs in
            let l = abs(lhs.row - start.row) + abs(lhs.col - start.col)
            let r = abs(rhs.row - start.row) + abs(rhs.col - start.col)
            return l < r
        }) {
            safeZone = farthest
        } else {
            safeZone = start
        }
    }

    private func drawGrid() {
        tileNodes.forEach { row in row.forEach { $0.removeFromParent() } }
        tileNodes = []

        for r in 0..<gridRows {
            var row: [SKShapeNode] = []
            for c in 0..<gridCols {
                let node = SKShapeNode(rectOf: CGSize(width: tileSize - 2, height: tileSize - 2), cornerRadius: 3)
                node.position = positionFor(row: r, col: c)
                node.lineWidth = 0
                node.zPosition = 0

                if walls.contains(GridPos(row: r, col: c)) {
                    node.fillColor = SKColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
                } else {
                    node.fillColor = HeatState.cold.color
                }
                addChild(node)
                row.append(node)
            }
            tileNodes.append(row)
        }
    }

    private func drawPlayer() {
        playerNode?.removeFromParent()
        let skin = StorageService.shared.equippedSkin
        playerNode = SKShapeNode(circleOfRadius: tileSize * 0.35)
        playerNode.zPosition = 10

        switch skin {
        case "golden": playerNode.fillColor = SKColor(red: 1, green: 0.84, blue: 0, alpha: 1)
        case "fire": playerNode.fillColor = SKColor(red: 1, green: 0.4, blue: 0.1, alpha: 1)
        case "ice": playerNode.fillColor = SKColor(red: 0.5, green: 0.8, blue: 1, alpha: 1)
        case "ninja": playerNode.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.3, alpha: 1)
        default: playerNode.fillColor = SKColor(red: 1, green: 1, blue: 0.9, alpha: 1)
        }

        playerNode.strokeColor = .clear
        playerNode.position = positionFor(row: movementController.playerRow, col: movementController.playerCol)

        let beak = SKShapeNode(rectOf: CGSize(width: tileSize * 0.15, height: tileSize * 0.1))
        beak.fillColor = SKColor(red: 1, green: 0.6, blue: 0, alpha: 1)
        beak.strokeColor = .clear
        beak.position = CGPoint(x: tileSize * 0.3, y: 0)
        beak.zPosition = 11
        playerNode.addChild(beak)

        let eye = SKShapeNode(circleOfRadius: tileSize * 0.08)
        eye.fillColor = .black
        eye.strokeColor = .clear
        eye.position = CGPoint(x: tileSize * 0.1, y: tileSize * 0.1)
        eye.zPosition = 11
        playerNode.addChild(eye)

        addChild(playerNode)
    }

    private func drawEggs() {
        eggNodes.forEach { $0.removeFromParent() }
        eggNodes = []

        for egg in eggs {
            let node = SKShapeNode(ellipseOf: CGSize(width: tileSize * 0.4, height: tileSize * 0.5))
            node.fillColor = egg.displayColor
            node.strokeColor = SKColor(white: 0.7, alpha: 0.5)
            node.lineWidth = 1
            node.position = positionFor(row: egg.row, col: egg.col)
            node.zPosition = 5
            node.isHidden = egg.isDead || egg.isPickedUp
            addChild(node)
            eggNodes.append(node)
        }
    }

    private func drawSafeZone() {
        safeZoneNode?.removeFromParent()
        safeZoneNode = SKShapeNode(rectOf: CGSize(width: tileSize - 4, height: tileSize - 4), cornerRadius: 4)
        safeZoneNode.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 0.3)
        safeZoneNode.strokeColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 0.8)
        safeZoneNode.lineWidth = 2
        safeZoneNode.position = positionFor(row: safeZone.row, col: safeZone.col)
        safeZoneNode.zPosition = 1

        let pulse = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.8),
            SKAction.fadeAlpha(to: 1.0, duration: 0.8)
        ])
        safeZoneNode.run(SKAction.repeatForever(pulse))
        addChild(safeZoneNode)

        let label = SKLabelNode(text: "SAFE")
        label.fontSize = tileSize * 0.25
        label.fontName = "Helvetica-Bold"
        label.fontColor = SKColor(red: 0.2, green: 0.8, blue: 0.3, alpha: 1)
        label.verticalAlignmentMode = .center
        label.zPosition = 2
        safeZoneNode.addChild(label)
    }

    private func positionFor(row: Int, col: Int) -> CGPoint {
        CGPoint(
            x: gridOrigin.x + CGFloat(col) * tileSize + tileSize / 2,
            y: gridOrigin.y + CGFloat(gridRows - 1 - row) * tileSize + tileSize / 2
        )
    }

    @objc private func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        guard !gameOver else { return }
        let direction: Direction
        switch gesture.direction {
        case .up: direction = .up
        case .down: direction = .down
        case .left: direction = .left
        case .right: direction = .right
        default: return
        }
        lastDirection = direction

        if movementController.move(direction: direction) {
            StorageService.shared.totalDistance += 1
            GameFeedbackService.shared.impact(.light)
            updatePlayerPosition()
            checkPickup()
            checkDelivery()
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard !gameOver else { return }
        let storage = StorageService.shared
        guard storage.iceBurstCount > 0 else { return }
        storage.iceBurstCount -= 1
        gameDelegate?.iceBurstCountDidChange(storage.iceBurstCount)
        GameFeedbackService.shared.play(.iceBurst)
        GameFeedbackService.shared.impact(.medium)

        let pos = movementController.playerPosition
        heatSystem.iceBurst(centerRow: pos.row, centerCol: pos.col)

        let burst = SKShapeNode(circleOfRadius: tileSize * 2.5)
        burst.fillColor = SKColor(red: 0.5, green: 0.8, blue: 1, alpha: 0.3)
        burst.strokeColor = SKColor(red: 0.5, green: 0.8, blue: 1, alpha: 0.8)
        burst.position = positionFor(row: pos.row, col: pos.col)
        burst.zPosition = 20
        addChild(burst)
        burst.run(SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2, duration: 0.3),
                SKAction.fadeOut(withDuration: 0.3)
            ]),
            SKAction.removeFromParent()
        ]))
    }

    private func updatePlayerPosition() {
        let pos = positionFor(row: movementController.playerRow, col: movementController.playerCol)
        playerNode.run(SKAction.move(to: pos, duration: 0.1))

        if playerHasEgg, let idx = carriedEggIndex, idx < eggs.count {
            eggs[idx].row = movementController.playerRow
            eggs[idx].col = movementController.playerCol
        }
    }

    private func checkPickup() {
        guard !playerHasEgg else { return }
        let playerPos = movementController.playerPosition
        for i in 0..<eggs.count {
            if !eggs[i].isDead && !eggs[i].isPickedUp && eggs[i].row == playerPos.row && eggs[i].col == playerPos.col {
                eggs[i].isPickedUp = true
                carriedEggIndex = i
                playerHasEgg = true
                if i < eggNodes.count {
                    eggNodes[i].isHidden = true
                }
                GameFeedbackService.shared.play(.pickup)
                GameFeedbackService.shared.impact(.light)
                emitEggsRemaining()
                break
            }
        }
    }

    private func checkDelivery() {
        guard playerHasEgg, let idx = carriedEggIndex else { return }
        let playerPos = movementController.playerPosition
        guard playerPos == safeZone else { return }

        let egg = eggs[idx]
        let noDamage = gameContext.noDamage
        let timeBonus = egg.timeRemaining > egg.timeRemaining * 0.5
        deliveryStreak += 1
        let streakBonus = deliveryStreak >= 2 ? min(deliveryStreak - 1, 4) : 0

        let reward = EconomyService.shared.rewardForEggRescue(type: egg.type, timeBonus: timeBonus, noDamage: noDamage)

        EconomyService.shared.addCoins(reward)
        totalCoinsEarned += reward
        if streakBonus > 0 {
            EconomyService.shared.addCoins(streakBonus)
            totalCoinsEarned += streakBonus
        }
        totalEggsRescued += 1
        StorageService.shared.eggsRescued += 1

        if egg.type == .golden {
            StorageService.shared.goldenEggsSaved += 1
            gameContext.savedGoldenEgg = true
        }

        if egg.type == .double {
            totalEggsRescued += 1
            StorageService.shared.eggsRescued += 1
            EconomyService.shared.addCoins(reward / 2)
            totalCoinsEarned += reward / 2
        }

        if noDamage {
            perfectDeliveries += 1
            gameContext.consecutivePerfectDeliveries = perfectDeliveries
        } else {
            perfectDeliveries = 0
        }

        playerHasEgg = false
        carriedEggIndex = nil

        let effect = SKLabelNode(text: "+\(reward)")
        effect.fontSize = 20
        effect.fontName = "Helvetica-Bold"
        effect.fontColor = SKColor(red: 0.96, green: 0.77, blue: 0.26, alpha: 1)
        effect.position = positionFor(row: safeZone.row, col: safeZone.col)
        effect.zPosition = 30
        addChild(effect)
        effect.run(SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 40, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            SKAction.removeFromParent()
        ]))

        if streakBonus > 0 {
            let streakLabel = SKLabelNode(text: "STREAK ×\(deliveryStreak)  +\(streakBonus)")
            streakLabel.fontSize = 15
            streakLabel.fontName = "Helvetica-Bold"
            streakLabel.fontColor = SKColor(red: 1.0, green: 0.48, blue: 0.0, alpha: 1)
            streakLabel.position = CGPoint(x: positionFor(row: safeZone.row, col: safeZone.col).x, y: positionFor(row: safeZone.row, col: safeZone.col).y - tileSize * 0.35)
            streakLabel.zPosition = 30
            addChild(streakLabel)
            streakLabel.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: 0, y: 28, duration: 0.55),
                    SKAction.fadeOut(withDuration: 0.55)
                ]),
                SKAction.removeFromParent()
            ]))
        }

        gameDelegate?.deliveryStreakDidChange(deliveryStreak)
        gameDelegate?.coinsDidChange(StorageService.shared.coins)
        GameFeedbackService.shared.play(.delivery)
        GameFeedbackService.shared.notify(.success)

        let remaining = eggs.filter { !$0.isDead && !$0.isPickedUp }.count
        emitEggsRemaining()

        if remaining == 0 {
            levelComplete()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        guard !gameOver else { return }
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = min(currentTime - lastUpdateTime, 0.1)
        lastUpdateTime = currentTime
        levelTime += dt
        gameContext.levelTime = levelTime

        movementController.update(deltaTime: dt)
        checkPickup()
        checkDelivery()
        heatSystem.update(deltaTime: dt, level: level)
        heatSystem.coolTile(row: safeZone.row, col: safeZone.col, radius: 0)
        updateTileColors()
        updateEggTimers(dt: dt)
        checkHeatDamage(dt: dt)
        gameDelegate?.timerDidChange(levelTime)
    }

    private func updateTileColors() {
        for r in 0..<gridRows {
            for c in 0..<gridCols {
                guard !walls.contains(GridPos(row: r, col: c)) else { continue }
                let state = heatSystem.heatState(at: r, col: c)
                tileNodes[r][c].fillColor = state.color
            }
        }
    }

    private func updateEggTimers(dt: TimeInterval) {
        for i in 0..<eggs.count {
            guard !eggs[i].isDead && !eggs[i].isPickedUp else { continue }
            eggs[i].timeRemaining -= dt
            if eggs[i].timeRemaining <= 0 {
                eggs[i].isDead = true
                if i < eggNodes.count {
                    eggNodes[i].isHidden = true
                    let crack = SKLabelNode(text: "X")
                    crack.fontSize = tileSize * 0.5
                    crack.fontColor = .red
                    crack.position = positionFor(row: eggs[i].row, col: eggs[i].col)
                    crack.zPosition = 25
                    addChild(crack)
                    crack.run(SKAction.sequence([
                        SKAction.fadeOut(withDuration: 1.0),
                        SKAction.removeFromParent()
                    ]))
                }
                gameDelegate?.eggsRemainingDidChange(
                    eggs.filter { !$0.isDead && !$0.isPickedUp }.count
                )
                checkAllEggsDead()
            }

            if eggs[i].timeRemaining > 0 && eggs[i].timeRemaining < 5 && i < eggNodes.count && !eggNodes[i].isHidden {
                if eggNodes[i].action(forKey: "pulse") == nil {
                    let pulse = SKAction.sequence([
                        SKAction.fadeAlpha(to: 0.3, duration: 0.3),
                        SKAction.fadeAlpha(to: 1.0, duration: 0.3)
                    ])
                    eggNodes[i].run(SKAction.repeatForever(pulse), withKey: "pulse")
                }
            }
        }
    }

    private func checkHeatDamage(dt: TimeInterval) {
        let pos = movementController.playerPosition
        if pos == safeZone { return }
        let state = heatSystem.heatState(at: pos.row, col: pos.col)

        let effectiveResistance = heatResistance

        switch state {
        case .cold, .warm:
            break
        case .hot:
            gameContext.survivedHotZoneSeconds += dt
            if playerHasEgg, let idx = carriedEggIndex, eggs[idx].type == .fragile {
                if effectiveResistance < 0.3 {
                    gameContext.noDamage = false
                }
            }
        case .lethal:
            if effectiveResistance >= 0.3 {
                gameContext.survivedHotZoneSeconds += dt
            } else {
                if playerHasEgg, let idx = carriedEggIndex {
                    eggs[idx].isDead = true
                    playerHasEgg = false
                    carriedEggIndex = nil
                    gameContext.noDamage = false
                    resetDeliveryStreak()

                    let crack = SKLabelNode(text: "X")
                    crack.fontSize = tileSize * 0.5
                    crack.fontColor = .red
                    crack.position = playerNode.position
                    crack.zPosition = 25
                    addChild(crack)
                    crack.run(SKAction.sequence([
                        SKAction.fadeOut(withDuration: 0.5),
                        SKAction.removeFromParent()
                    ]))

                    gameDelegate?.eggsRemainingDidChange(
                        eggs.filter { !$0.isDead && !$0.isPickedUp }.count
                    )
                    checkAllEggsDead()
                }

                if !hasExtraLife || extraLifeUsed {
                    playerNode.run(SKAction.sequence([
                        SKAction.colorize(with: .red, colorBlendFactor: 1, duration: 0.1),
                        SKAction.colorize(withColorBlendFactor: 0, duration: 0.1)
                    ]))
                } else if hasExtraLife && !extraLifeUsed {
                    extraLifeUsed = true
                    StorageService.shared.extraLifeCount -= 1
                    heatSystem.coolTile(row: pos.row, col: pos.col, radius: 1)
                }
            }
        }
    }

    private func checkAllEggsDead() {
        let remaining = eggs.filter { !$0.isDead && !$0.isPickedUp }.count
        let carried = playerHasEgg ? 1 : 0
        if remaining == 0 && carried == 0 {
            endGame()
        }
    }

    private func reachableWalkableCells(from start: GridPos) -> Set<GridPos> {
        guard !walls.contains(start) else { return [] }
        var visited: Set<GridPos> = [start]
        var queue: [GridPos] = [start]

        while !queue.isEmpty {
            let current = queue.removeFirst()
            for dir in [Direction.up, .down, .left, .right] {
                let next = GridPos(row: current.row + dir.dr, col: current.col + dir.dc)
                let inside = next.row > 0 && next.row < gridRows - 1 && next.col > 0 && next.col < gridCols - 1
                if inside && !walls.contains(next) && !visited.contains(next) {
                    visited.insert(next)
                    queue.append(next)
                }
            }
        }
        return visited
    }

    private func emitEggsRemaining() {
        gameDelegate?.eggsRemainingDidChange(eggs.filter { !$0.isDead && !$0.isPickedUp }.count)
    }

    private func resetDeliveryStreak() {
        guard deliveryStreak != 0 else { return }
        deliveryStreak = 0
        gameDelegate?.deliveryStreakDidChange(0)
    }

    private func levelComplete() {
        gameOver = true
        gameContext.levelCompleted = true
        GameFeedbackService.shared.play(.levelComplete)
        GameFeedbackService.shared.notify(.success)
        StorageService.shared.fastestRun = levelTime
        StorageService.shared.highestLevel = level + 1

        let totalGames = StorageService.shared.totalGamesPlayed
        let survived = Double(totalEggsRescued) / Double(max(1, eggs.count)) * 100
        StorageService.shared.heatSurvivalPercent = (StorageService.shared.heatSurvivalPercent * Double(totalGames) + survived) / Double(totalGames + 1)
        StorageService.shared.totalGamesPlayed += 1

        AchievementService.shared.checkAchievements(context: gameContext)
        gameDelegate?.gameDidEnd(eggsRescued: totalEggsRescued, coinsEarned: totalCoinsEarned, context: gameContext)
    }

    private func endGame() {
        gameOver = true
        gameContext.levelCompleted = false
        GameFeedbackService.shared.play(.gameOver)
        GameFeedbackService.shared.notify(.error)
        StorageService.shared.highestLevel = level

        let totalGames = StorageService.shared.totalGamesPlayed
        let survived = Double(totalEggsRescued) / Double(max(1, eggs.count)) * 100
        StorageService.shared.heatSurvivalPercent = (StorageService.shared.heatSurvivalPercent * Double(totalGames) + survived) / Double(totalGames + 1)
        StorageService.shared.totalGamesPlayed += 1

        AchievementService.shared.checkAchievements(context: gameContext)
        gameDelegate?.gameDidEnd(eggsRescued: totalEggsRescued, coinsEarned: totalCoinsEarned, context: gameContext)
    }
}
