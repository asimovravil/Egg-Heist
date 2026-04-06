import SwiftUI

struct MainMenuView: View {
    @State private var showLevelSelect = false
    @State private var showShop = false
    @State private var showStats = false
    @State private var showChallenges = false
    @State private var showSettings = false
    @State private var heatPhase: Double = 0

    private let warmYellow = Color(red: 0.96, green: 0.77, blue: 0.26)
    private let hotOrange = Color(red: 1.0, green: 0.48, blue: 0.0)
    private let deepRed = Color(red: 0.9, green: 0.0, blue: 0.15)
    private let creamWhite = Color(red: 1.0, green: 0.96, blue: 0.88)

    var body: some View {
        ZStack {
            GameBackgroundView().ignoresSafeArea()
            heatMapBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300)
                .shadow(color: hotOrange.opacity(0.5), radius: 20)
                .padding(.bottom, 60)

                imageMenuButton(assetName: "rescue", width: 250) {
                    showLevelSelect = true
                }
                .padding(.bottom, 24)

                HStack(spacing: 16) {
                    imageMenuButton(assetName: "shop", width: 165) { showShop = true }
                    imageMenuButton(assetName: "stats", width: 165) { showStats = true }
                }
                .padding(.bottom, 12)

                imageMenuButton(assetName: "challenges", width: 250) { showChallenges = true }
                    .padding(.bottom, 12)

                imageMenuButton(assetName: "settings", width: 250) { showSettings = true }

                Spacer()
            }
        }
        .fullScreenCover(isPresented: $showLevelSelect) {
            LevelSelectView()
        }
        .sheet(isPresented: $showShop) {
            ShopView()
        }
        .sheet(isPresented: $showStats) {
            StatsView()
        }
        .sheet(isPresented: $showChallenges) {
            ChallengesView()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: true)) {
                heatPhase = 1
            }
        }
    }

    private var heatMapBackground: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [deepRed.opacity(0.15), .clear], center: .center, startRadius: 0, endRadius: 200)
                )
                .frame(width: 400, height: 400)
                .offset(x: heatPhase * 30 - 15, y: heatPhase * 20 - 150)

            Circle()
                .fill(
                    RadialGradient(colors: [hotOrange.opacity(0.1), .clear], center: .center, startRadius: 0, endRadius: 150)
                )
                .frame(width: 300, height: 300)
                .offset(x: -heatPhase * 40 + 80, y: heatPhase * 30 + 100)

            Circle()
                .fill(
                    RadialGradient(colors: [warmYellow.opacity(0.08), .clear], center: .center, startRadius: 0, endRadius: 180)
                )
                .frame(width: 360, height: 360)
                .offset(x: heatPhase * 50 - 100, y: -heatPhase * 25 + 200)
        }
    }

    private func imageMenuButton(assetName: String, width: CGFloat, action: @escaping () -> Void) -> some View {
        Button {
            GameFeedbackService.shared.play(.tap)
            GameFeedbackService.shared.impact(.light)
            action()
        } label: {
            Image(assetName)
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .shadow(color: hotOrange.opacity(0.35), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
    }
}

struct LevelSelectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showGame = false
    @State private var selectedLevel = 1
    @State private var pendingAutoStartLevel: Int?

    private let warmYellow = Color(red: 0.96, green: 0.77, blue: 0.26)
    private let hotOrange = Color(red: 1.0, green: 0.48, blue: 0.0)
    private let deepRed = Color(red: 0.9, green: 0.0, blue: 0.15)
    private let darkBg = Color(red: 0.063, green: 0.063, blue: 0.063)
    private let creamWhite = Color(red: 1.0, green: 0.96, blue: 0.88)

    private let maxLevels = 12
    private var unlockedLevel: Int { max(1, StorageService.shared.highestLevel) }
    private func columns(compact: Bool) -> [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: compact ? 10 : 12), count: compact ? 2 : 3)
    }

    var body: some View {
        ZStack {
            GameBackgroundView().ignoresSafeArea()
            backgroundHeat
                .ignoresSafeArea()

            GeometryReader { geo in
                let compact = geo.size.width < 390 || geo.size.height < 760

                VStack(spacing: 0) {
                    HStack {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(creamWhite)
                                .frame(width: 40, height: 40)
                                .background(Color.black.opacity(0.3))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 4)
                        Spacer()
                        Text("SELECT LEVEL")
                            .font(.system(size: compact ? 20 : 22, weight: .black, design: .rounded))
                            .foregroundColor(warmYellow)
                            .shadow(color: .black.opacity(0.4), radius: 8, y: 2)
                        Spacer()
                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Text("Unlocked: \(unlockedLevel)/\(maxLevels)")
                        .font(.system(size: compact ? 12 : 13, weight: .black, design: .rounded))
                        .foregroundColor(creamWhite.opacity(0.9))
                        .padding(.top, 8)
                        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)

                    ScrollView {
                        LazyVGrid(columns: columns(compact: compact), spacing: compact ? 10 : 12) {
                            ForEach(1...maxLevels, id: \.self) { level in
                                levelCard(level, compact: compact)
                            }
                        }
                        .padding(.horizontal, compact ? 14 : 16)
                        .padding(.top, compact ? 18 : 24)
                        .padding(.bottom, 20)
                    }
                    .background(Color.black.opacity(0.28))
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                }
            }
        }
        .fullScreenCover(isPresented: $showGame) {
            GameView(initialLevel: selectedLevel) { nextLevel in
                pendingAutoStartLevel = nextLevel
            } onClose: {
                showGame = false
            }
        }
        .onChange(of: showGame) { isPresented in
            guard !isPresented, let next = pendingAutoStartLevel else { return }
            pendingAutoStartLevel = nil
            let clamped = min(max(1, next), maxLevels)
            guard clamped <= unlockedLevel else { return }
            selectedLevel = clamped
            showGame = true
        }
    }

    private var backgroundHeat: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [hotOrange.opacity(0.14), .clear], center: .center, startRadius: 0, endRadius: 220))
                .frame(width: 420, height: 420)
                .offset(x: -120, y: -220)
            Circle()
                .fill(RadialGradient(colors: [deepRed.opacity(0.12), .clear], center: .center, startRadius: 0, endRadius: 200))
                .frame(width: 360, height: 360)
                .offset(x: 130, y: 240)
        }
    }

    private func levelCard(_ level: Int, compact: Bool) -> some View {
        let locked = level > unlockedLevel
        return Button {
            guard !locked else { return }
            selectedLevel = level
            showGame = true
        } label: {
            VStack(spacing: 10) {
                Text("LEVEL")
                    .font(.system(size: compact ? 11 : 12, weight: .black, design: .rounded))
                    .foregroundColor(locked ? creamWhite.opacity(0.8) : creamWhite.opacity(0.72))
                Text("\(level)")
                    .font(.system(size: compact ? 34 : 30, weight: .black, design: .rounded))
                    .foregroundColor(locked ? creamWhite.opacity(0.9) : .black)
                Image(systemName: locked ? "lock.fill" : "flame.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(locked ? creamWhite.opacity(0.85) : hotOrange)
            }
            .frame(maxWidth: .infinity)
            .frame(height: compact ? 116 : 120)
            .background(
                Group {
                    if locked {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.48))
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(LinearGradient(colors: [warmYellow, hotOrange], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(locked ? 0.18 : 0.25), lineWidth: 1)
            )
            .shadow(color: locked ? .clear : hotOrange.opacity(0.35), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(locked)
    }
}
