import SwiftUI

struct ChallengesView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ChallengeViewModel()

    private let warmYellow = Color(red: 0.96, green: 0.77, blue: 0.26)
    private let hotOrange = Color(red: 1.0, green: 0.48, blue: 0.0)
    private let darkBg = Color(red: 0.063, green: 0.063, blue: 0.063)
    private let creamWhite = Color(red: 1.0, green: 0.96, blue: 0.88)

    var body: some View {
        ZStack {
            GameBackgroundView().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    challengeSection("Daily Challenges", challenges: viewModel.dailyChallenges)
                    challengeSection("Weekly Challenges", challenges: viewModel.weeklyChallenges)
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
            Text("CHALLENGES")
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(warmYellow)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
    }

    private func challengeSection(_ title: String, challenges: [Challenge]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(warmYellow)
                .shadow(color: .black.opacity(0.4), radius: 8, y: 2)

            ForEach(challenges) { challenge in
                challengeRow(challenge)
            }
        }
    }

    private func challengeRow(_ challenge: Challenge) -> some View {
        HStack(spacing: 12) {
            Image(systemName: challenge.icon)
                .font(.title3)
                .foregroundColor(challenge.isComplete ? .green : warmYellow)
                .frame(width: 36, height: 36)
                .background(challenge.isComplete ? Color.green.opacity(0.15) : warmYellow.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(challenge.name)
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(creamWhite)
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
                Text(challenge.description)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(creamWhite.opacity(0.8))

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(challenge.isComplete ? Color.green : hotOrange)
                            .frame(width: geo.size.width * CGFloat(challenge.progress) / CGFloat(max(1, challenge.requirement)), height: 6)
                    }
                }
                .frame(height: 6)
            }

            Spacer()

            Text("\(challenge.progress)/\(challenge.requirement)")
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(challenge.isComplete ? .green : creamWhite.opacity(0.5))
        }
        .padding(12)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
