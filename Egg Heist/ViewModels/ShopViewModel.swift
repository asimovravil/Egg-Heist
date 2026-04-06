import Combine
import SwiftUI

struct ShopItem: Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Int
    let icon: String
    var isOwned: Bool = false
    var isEquipped: Bool = false
    var currentLevel: Int = 0
    var maxLevel: Int = 1
}

final class ShopViewModel: ObservableObject {
    @Published var coins: Int = 0
    @Published var items: [ShopItem] = []
    @Published var purchaseMessage: String? = nil

    private let storage = StorageService.shared
    private let economy = EconomyService.shared

    func load() {
        coins = storage.coins
        buildItems()
    }

    private func buildItems() {
        items = []

        let speedLvl = storage.speedLevel
        items.append(ShopItem(
            id: "speed", name: "Faster Chicken", description: "Move quicker through the maze",
            price: economy.speedUpgradePrice(level: speedLvl), icon: "hare.fill",
            currentLevel: speedLvl, maxLevel: 5
        ))

        let heatLvl = storage.heatResistLevel
        items.append(ShopItem(
            id: "heat_resist", name: "Heat Resistance", description: "Survive hot zones longer",
            price: economy.heatResistPrice(level: heatLvl), icon: "flame.fill",
            currentLevel: heatLvl, maxLevel: 5
        ))

        items.append(ShopItem(
            id: "ice_burst", name: "Ice Burst", description: "Cool down surrounding tiles (x\(storage.iceBurstCount))",
            price: economy.iceBurstPrice, icon: "snowflake",
        ))

        items.append(ShopItem(
            id: "extra_life", name: "Extra Life Egg", description: "Survive one lethal hit (x\(storage.extraLifeCount))",
            price: economy.extraLifePrice, icon: "heart.fill",
        ))

        let ownedSkins = storage.ownedSkins
        let equippedSkin = storage.equippedSkin
        let skins = [
            ("default", "Classic Chicken", "chicken.fill"),
            ("golden", "Golden Chicken", "star.fill"),
            ("fire", "Fire Chicken", "flame.fill"),
            ("ice", "Ice Chicken", "snowflake"),
            ("ninja", "Ninja Chicken", "eye.slash.fill"),
        ]

        for (skinId, skinName, skinIcon) in skins {
            items.append(ShopItem(
                id: "skin_\(skinId)", name: skinName,
                description: skinId == "default" ? "Default skin" : "Premium skin",
                price: skinId == "default" ? 0 : economy.skinPrice(skinId),
                icon: skinIcon,
                isOwned: ownedSkins.contains(skinId),
                isEquipped: equippedSkin == skinId
            ))
        }
    }

    func purchase(_ item: ShopItem) {
        switch item.id {
        case "speed":
            guard storage.speedLevel < 5 else {
                purchaseMessage = "Max level reached!"
                GameFeedbackService.shared.play(.error)
                GameFeedbackService.shared.notify(.warning)
                return
            }
            guard economy.spendCoins(item.price) else {
                purchaseMessage = "Not enough coins!"
                GameFeedbackService.shared.play(.error)
                GameFeedbackService.shared.notify(.error)
                return
            }
            storage.speedLevel += 1
            purchaseMessage = "Speed upgraded!"
            GameFeedbackService.shared.play(.delivery)
            GameFeedbackService.shared.notify(.success)

        case "heat_resist":
            guard storage.heatResistLevel < 5 else {
                purchaseMessage = "Max level reached!"
                GameFeedbackService.shared.play(.error)
                GameFeedbackService.shared.notify(.warning)
                return
            }
            guard economy.spendCoins(item.price) else {
                purchaseMessage = "Not enough coins!"
                GameFeedbackService.shared.play(.error)
                GameFeedbackService.shared.notify(.error)
                return
            }
            storage.heatResistLevel += 1
            purchaseMessage = "Heat resistance upgraded!"
            GameFeedbackService.shared.play(.delivery)
            GameFeedbackService.shared.notify(.success)

        case "ice_burst":
            guard economy.spendCoins(item.price) else {
                purchaseMessage = "Not enough coins!"
                GameFeedbackService.shared.play(.error)
                GameFeedbackService.shared.notify(.error)
                return
            }
            storage.iceBurstCount += 1
            purchaseMessage = "Ice Burst purchased!"
            GameFeedbackService.shared.play(.delivery)
            GameFeedbackService.shared.notify(.success)

        case "extra_life":
            guard economy.spendCoins(item.price) else {
                purchaseMessage = "Not enough coins!"
                GameFeedbackService.shared.play(.error)
                GameFeedbackService.shared.notify(.error)
                return
            }
            storage.extraLifeCount += 1
            purchaseMessage = "Extra Life purchased!"
            GameFeedbackService.shared.play(.delivery)
            GameFeedbackService.shared.notify(.success)

        default:
            if item.id.hasPrefix("skin_") {
                let skinId = String(item.id.dropFirst(5))
                if item.isOwned {
                    storage.equippedSkin = skinId
                    purchaseMessage = "\(item.name) equipped!"
                    GameFeedbackService.shared.play(.tap)
                    GameFeedbackService.shared.impact(.medium)
                } else {
                    guard economy.spendCoins(item.price) else {
                        purchaseMessage = "Not enough coins!"
                        GameFeedbackService.shared.play(.error)
                        GameFeedbackService.shared.notify(.error)
                        return
                    }
                    var owned = storage.ownedSkins
                    owned.append(skinId)
                    storage.ownedSkins = owned
                    storage.equippedSkin = skinId
                    purchaseMessage = "\(item.name) unlocked!"
                    GameFeedbackService.shared.play(.delivery)
                    GameFeedbackService.shared.notify(.success)
                }
            }
        }

        load()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.purchaseMessage = nil
        }
    }
}
