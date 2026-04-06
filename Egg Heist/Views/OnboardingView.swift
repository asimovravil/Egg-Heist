import SwiftUI
import Combine

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var swipeHintShift: CGFloat = -8
    @State private var arenaStep = 0
    let onFinished: () -> Void

    private let warmYellow = Color(red: 0.96, green: 0.77, blue: 0.26)
    private let hotOrange = Color(red: 1.0, green: 0.48, blue: 0.0)
    private let deepRed = Color(red: 0.9, green: 0.0, blue: 0.15)
    private let darkBg = Color(red: 0.063, green: 0.063, blue: 0.063)
    private let creamWhite = Color(red: 1.0, green: 0.96, blue: 0.88)

    private let pages: [(icon: String, title: String, subtitle: String)] = [
        ("figure.walk", "Move Fast", "Swipe to navigate through the maze.\nEvery second counts."),
        ("flame.fill", "Avoid Heat", "Tiles heat up over time.\nOrange is dangerous. Red destroys eggs."),
        (AppSymbol.egg, "Save Eggs", "Pick up eggs and deliver them\nto the safe zone before time runs out."),
    ]

    var body: some View {
        ZStack {
            GameBackgroundView().ignoresSafeArea()

            GeometryReader { geo in
                let compactScreen = geo.size.height < 760 || geo.size.width < 370

                VStack(spacing: 0) {
                    Spacer()

                    miniMaze(compact: compactScreen)
                        .padding(.bottom, compactScreen ? 24 : 40)

                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            VStack(spacing: compactScreen ? 12 : 16) {
                                Image(systemName: pages[index].icon)
                                    .font(.system(size: compactScreen ? 42 : 48))
                                    .foregroundColor(warmYellow)

                                VStack(spacing: compactScreen ? 6 : 8) {
                                    Text(pages[index].title)
                                        .font(.system(size: compactScreen ? 30 : 34, weight: .black, design: .rounded))
                                        .foregroundColor(creamWhite)
                                        .shadow(color: .black.opacity(0.45), radius: 8, y: 3)

                                    Text(pages[index].subtitle)
                                        .font(.system(size: compactScreen ? 16 : 18, weight: .bold, design: .rounded))
                                        .foregroundColor(creamWhite)
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(compactScreen ? 2 : 3)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .shadow(color: .black.opacity(0.45), radius: 8, y: 3)
                                }
                                .padding(.horizontal, compactScreen ? 14 : 18)
                                .padding(.vertical, compactScreen ? 12 : 14)
                                .background(Color.black.opacity(0.35))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .padding(.horizontal, compactScreen ? 16 : 20)
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: compactScreen ? 210 : 240)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 20).onEnded { value in
                            if value.translation.width < -40, currentPage < pages.count - 1 {
                                withAnimation { currentPage += 1 }
                            } else if value.translation.width > 40, currentPage > 0 {
                                withAnimation { currentPage -= 1 }
                            }
                        }
                    )

                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(index == currentPage ? warmYellow : Color.white.opacity(0.35))
                                .frame(width: index == currentPage ? 24 : 8, height: 8)
                                .animation(.easeInOut(duration: 0.2), value: currentPage)
                        }
                    }
                    .padding(.top, compactScreen ? 8 : 12)

                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .offset(x: swipeHintShift)
                        Text("Swipe")
                        Image(systemName: "chevron.right")
                            .offset(x: -swipeHintShift)
                    }
                    .font(.system(size: compactScreen ? 11 : 12, weight: .bold, design: .rounded))
                    .foregroundColor(creamWhite.opacity(0.8))
                    .padding(.top, compactScreen ? 6 : 8)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                            swipeHintShift = 8
                        }
                    }
                    .onReceive(Timer.publish(every: 0.45, on: .main, in: .common).autoconnect()) { _ in
                        arenaStep = (arenaStep + 1) % arenaPath.count
                    }

                    Spacer()

                    Text("\"The heat is rising.\nSave them before it's too late.\"")
                        .font(.system(size: compactScreen ? 12 : 14, weight: .medium, design: .serif).italic())
                        .foregroundColor(creamWhite.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(.bottom, compactScreen ? 14 : 24)

                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation { currentPage += 1 }
                        } else {
                            StorageService.shared.hasSeenOnboarding = true
                            onFinished()
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "NEXT" : "START RESCUE")
                            .font(.system(size: compactScreen ? 16 : 17, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: compactScreen ? 48 : 52)
                            .background(
                                LinearGradient(colors: [warmYellow, hotOrange], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, compactScreen ? 24 : 32)
                    .padding(.bottom, compactScreen ? 20 : 40)
                }
            }
        }
    }

    private func miniMaze(compact: Bool) -> some View {
        let size: CGFloat = compact ? 20 : 24
        let grid: [[Int]] = [
            [1,1,1,1,1,1,1],
            [1,2,0,0,0,0,1],
            [1,0,1,1,0,1,1],
            [1,0,0,1,0,0,1],
            [1,1,0,0,0,1,1],
            [1,0,0,1,0,3,1],
            [1,1,1,1,1,1,1],
        ]

        return VStack(spacing: 2) {
            ForEach(0..<grid.count, id: \.self) { r in
                HStack(spacing: 2) {
                    ForEach(0..<grid[r].count, id: \.self) { c in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(cellColor(grid[r][c]))
                            .frame(width: size, height: size)
                            .overlay {
                                if isPlayerCell(row: r, col: c) {
                                    Circle()
                                        .fill(creamWhite)
                                        .frame(width: size * 0.6, height: size * 0.6)
                                        .shadow(color: warmYellow.opacity(0.65), radius: 4)
                                        .scaleEffect(arenaStep.isMultiple(of: 2) ? 1.0 : 0.88)
                                } else if grid[r][c] == 3 {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(Color.green.opacity(0.5))
                                        .frame(width: size * 0.7, height: size * 0.7)
                                }
                            }
                    }
                }
            }
        }
    }

    private func cellColor(_ value: Int) -> Color {
        switch value {
        case 1: return Color(red: 0.15, green: 0.15, blue: 0.15)
        case 2: return Color(red: 0.2, green: 0.2, blue: 0.2)
        case 3: return Color(red: 0.15, green: 0.3, blue: 0.15)
        default: return Color(red: 0.2, green: 0.2, blue: 0.2)
        }
    }

    private var arenaPath: [GridPos] {
        [
            GridPos(row: 1, col: 1),
            GridPos(row: 1, col: 2),
            GridPos(row: 1, col: 3),
            GridPos(row: 1, col: 4),
            GridPos(row: 2, col: 4),
            GridPos(row: 3, col: 4),
            GridPos(row: 4, col: 4),
            GridPos(row: 4, col: 5),
            GridPos(row: 5, col: 5),
            GridPos(row: 5, col: 4),
            GridPos(row: 4, col: 4),
            GridPos(row: 3, col: 4),
            GridPos(row: 2, col: 4),
            GridPos(row: 1, col: 4),
            GridPos(row: 1, col: 3),
            GridPos(row: 1, col: 2),
        ]
    }

    private func isPlayerCell(row: Int, col: Int) -> Bool {
        let pos = arenaPath[arenaStep]
        return pos.row == row && pos.col == col
    }
}
