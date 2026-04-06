import SwiftUI

struct StatsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = StatsViewModel()

    private let warmYellow = Color(red: 0.96, green: 0.77, blue: 0.26)
    private let hotOrange = Color(red: 1.0, green: 0.48, blue: 0.0)
    private let creamWhite = Color(red: 1.0, green: 0.96, blue: 0.88)

    var body: some View {
        ZStack {
            GameBackgroundView().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header

                    overviewStrip

                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Statistics")

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(viewModel.stats) { stat in
                                statCard(stat)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Achievements")

                        ForEach(viewModel.achievements) { achievement in
                            achievementRow(achievement)
                        }
                    }
                }
                .padding(16)
            }
        }
        .onAppear { viewModel.load() }
    }

    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(creamWhite)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }
            Spacer()
            Text("STATS")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(warmYellow)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 22, weight: .black, design: .rounded))
            .foregroundColor(warmYellow)
            .shadow(color: .black.opacity(0.4), radius: 8, y: 2)
    }

    private func statCard(_ stat: StatRow) -> some View {
        VStack(spacing: 8) {
            Image(systemName: stat.icon)
                .font(.title3)
                .foregroundColor(warmYellow)
            Text(stat.value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(creamWhite)
                .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
            Text(stat.name)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(creamWhite.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(14)
        .background(Color.black.opacity(0.36))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func achievementRow(_ achievement: Achievement) -> some View {
        HStack(spacing: 12) {
            Image(systemName: achievement.icon)
                .font(.title3)
                .foregroundColor(achievement.isUnlocked ? warmYellow : creamWhite.opacity(0.2))
                .frame(width: 36, height: 36)
                .background(achievement.isUnlocked ? warmYellow.opacity(0.15) : Color.white.opacity(0.03))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(achievement.isUnlocked ? creamWhite : creamWhite.opacity(0.4))
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
                Text(achievement.description)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(creamWhite.opacity(0.75))
            }

            Spacer()

            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(creamWhite.opacity(0.2))
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.33))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var overviewStrip: some View {
        HStack(spacing: 10) {
            if let level = viewModel.stats.first(where: { $0.name == "Highest Level" }) {
                overviewCard(title: "Current Peak", value: level.value, icon: "trophy.fill")
            }
            if let rescued = viewModel.stats.first(where: { $0.name == "Eggs Rescued" }) {
                overviewCard(title: "Eggs Saved", value: rescued.value, icon: AppSymbol.egg)
            }
            if let coins = viewModel.stats.first(where: { $0.name == "Total Coins" }) {
                overviewCard(title: "Total Coins", value: coins.value, icon: "dollarsign.circle.fill")
            }
        }
    }

    private func overviewCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(warmYellow)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundColor(creamWhite)
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(creamWhite.opacity(0.8))
        }
        .frame(maxWidth: .infinity, minHeight: 86)
        .background(
            LinearGradient(colors: [Color.black.opacity(0.42), hotOrange.opacity(0.24)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}
