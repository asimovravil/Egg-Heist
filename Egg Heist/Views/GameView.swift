import SwiftUI
import SpriteKit

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GameViewModel
    @State private var sceneId = UUID()
    @State private var skScene: LabyrinthScene?
    let onReturnToLevels: ((Int?) -> Void)?
    let onClose: (() -> Void)?

    private let warmYellow = Color(red: 0.96, green: 0.77, blue: 0.26)
    private let hotOrange = Color(red: 1.0, green: 0.48, blue: 0.0)
    private let darkBg = Color(red: 0.063, green: 0.063, blue: 0.063)
    private let creamWhite = Color(red: 1.0, green: 0.96, blue: 0.88)
    
    init(initialLevel: Int = 1, onReturnToLevels: ((Int?) -> Void)? = nil, onClose: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: GameViewModel(initialLevel: initialLevel))
        self.onReturnToLevels = onReturnToLevels
        self.onClose = onClose
    }

    var body: some View {
        ZStack {
            GameBackgroundView().ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(creamWhite.opacity(0.6))
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("Level \(viewModel.currentLevel)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(warmYellow)
                        Text(viewModel.formattedTime)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(creamWhite.opacity(0.7))
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        HStack(spacing: 3) {
                            Image(systemName: "snowflake")
                                .foregroundColor(.cyan)
                            Text("\(viewModel.iceBurstCount)")
                                .foregroundColor(creamWhite)
                        }
                        .font(.system(size: 13, weight: .semibold))

                        HStack(spacing: 3) {
                            Image(systemName: AppSymbol.egg)
                                .foregroundColor(warmYellow)
                            Text("\(viewModel.eggsRemaining)")
                                .foregroundColor(creamWhite)
                        }
                        .font(.system(size: 13, weight: .semibold))

                        HStack(spacing: 3) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(warmYellow)
                            Text("\(viewModel.coins)")
                                .foregroundColor(creamWhite)
                        }
                        .font(.system(size: 13, weight: .semibold))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                GeometryReader { geo in
                    ZStack {
                        if let scene = skScene {
                            SpriteView(
                                scene: scene,
                                transition: nil,
                                isPaused: false,
                                preferredFramesPerSecond: 60
                            )
                                .id(sceneId)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 4)
                        } else {
                            darkBg
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onAppear { createSceneIfNeeded(size: geo.size) }
                    .onChange(of: geo.size) { newSize in
                        createSceneIfNeeded(size: newSize)
                    }
                    .onChange(of: sceneId) { _ in
                        skScene = viewModel.createScene(size: geo.size)
                    }
                }
                .layoutPriority(1)

                Text("Swipe to move  |  Double-tap for Ice Burst")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(creamWhite.opacity(0.4))
                    .padding(.bottom, 8)
            }

            if viewModel.gameEnded {
                gameOverOverlay
            }
        }
        .statusBarHidden()
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: 20) {
                Text(viewModel.showNextLevel ? "LEVEL COMPLETE" : "GAME OVER")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(viewModel.showNextLevel ? warmYellow : .red)

                VStack(spacing: 8) {
                    resultRow(icon: AppSymbol.egg, label: "Eggs Rescued", value: "\(viewModel.eggsRescued)")
                    resultRow(icon: "dollarsign.circle.fill", label: "Coins Earned", value: "+\(viewModel.coinsEarned)")
                    resultRow(icon: "clock.fill", label: "Time", value: viewModel.formattedTime)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))

                HStack(spacing: 16) {
                    if viewModel.showNextLevel {
                        Button {
                            goToNextLevel()
                        } label: {
                            Text("NEXT LEVEL")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .frame(width: 150, height: 48)
                                .background(warmYellow)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }

                    Button {
                        restartLevel()
                    } label: {
                        Text("RESTART")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(creamWhite)
                            .frame(width: 120, height: 48)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }

                }
                .id(viewModel.showNextLevel ? "complete-actions" : "gameover-actions")
            }
            .padding(32)
        }
    }

    private func createSceneIfNeeded(size: CGSize) {
        guard skScene == nil, size.width > 1, size.height > 1 else { return }
        skScene = viewModel.createScene(size: size)
    }

    private func goToNextLevel() {
        guard viewModel.showNextLevel else { return }
        viewModel.nextLevel()
        sceneId = UUID()
    }

    private func restartLevel() {
        viewModel.restart()
        sceneId = UUID()
    }

    private func openLevels() {
        if viewModel.gameEnded, viewModel.showNextLevel {
            onReturnToLevels?(viewModel.currentLevel + 1)
        } else {
            onReturnToLevels?(nil)
        }
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private func resultRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(warmYellow)
                .frame(width: 24)
            Text(label)
                .foregroundColor(creamWhite.opacity(0.7))
            Spacer()
            Text(value)
                .foregroundColor(creamWhite)
                .fontWeight(.semibold)
        }
        .font(.system(size: 15, design: .rounded))
    }
}
