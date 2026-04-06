import SwiftUI

@main
struct Egg_HeistApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

enum AppSymbol {
    static let egg = "oval.fill"
}

struct GameBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            Image("bgmain")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .overlay(Color.black.opacity(0.32))
        }
    }
}
