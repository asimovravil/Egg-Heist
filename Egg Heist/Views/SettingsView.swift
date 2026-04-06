import SwiftUI
import SafariServices
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var soundEnabled: Bool = StorageService.shared.soundEnabled
    @State private var hapticEnabled: Bool = StorageService.shared.hapticEnabled
    @State private var showResetConfirm = false
    @State private var showOnboarding = false
    @State private var showPrivacyPolicy = false

    private let warmYellow = Color(red: 0.96, green: 0.77, blue: 0.26)
    private let hotOrange = Color(red: 1.0, green: 0.48, blue: 0.0)
    private let deepRed = Color(red: 0.9, green: 0.0, blue: 0.15)
    private let darkBg = Color(red: 0.063, green: 0.063, blue: 0.063)
    private let creamWhite = Color(red: 1.0, green: 0.96, blue: 0.88)
    private let privacyPolicyURL = URL(string: "https://example.com/privacy")!
    private let websiteURL = URL(string: "https://example.com")!

    var body: some View {
        ZStack {
            GameBackgroundView().ignoresSafeArea()

            ScrollView {
                VStack(spacing: 14) {
                    header

                    sectionTitle("Preferences")
                    settingToggleRow(
                        icon: "speaker.wave.2.fill",
                        title: "Sound",
                        subtitle: "Enable music and effects",
                        isOn: $soundEnabled
                    )
                    .onChange(of: soundEnabled) { value in
                        StorageService.shared.soundEnabled = value
                    }

                    settingToggleRow(
                        icon: "iphone.radiowaves.left.and.right",
                        title: "Haptic Feedback",
                        subtitle: "Vibration for interactions",
                        isOn: $hapticEnabled
                    )
                    .onChange(of: hapticEnabled) { value in
                        StorageService.shared.hapticEnabled = value
                    }

                    sectionTitle("Help")
                    actionRow(
                        icon: "book.fill",
                        title: "Replay Tutorial",
                        subtitle: "Show onboarding on next launch",
                        tint: warmYellow
                    ) {
                        showOnboarding = true
                        GameFeedbackService.shared.play(.tap)
                    }
                    actionRow(
                        icon: "doc.text.fill",
                        title: "Privacy Policy",
                        subtitle: "Open policy in in-app browser",
                        tint: warmYellow
                    ) {
                        showPrivacyPolicy = true
                        GameFeedbackService.shared.play(.tap)
                    }
                    actionRow(
                        icon: "arrow.up.right.square.fill",
                        title: "Open Website",
                        subtitle: "Simple external URL redirect",
                        tint: warmYellow
                    ) {
                        UIApplication.shared.open(websiteURL)
                    }
                    actionRow(
                        icon: "star.bubble.fill",
                        title: "Rate Us",
                        subtitle: "Leave a quick App Store rating",
                        tint: warmYellow
                    ) {
                        AppReviewService.shared.requestReview()
                        GameFeedbackService.shared.play(.tap)
                    }

                    sectionTitle("Danger Zone")
                    actionRow(
                        icon: "trash.fill",
                        title: "Reset All Progress",
                        subtitle: "Delete stats, coins and purchases",
                        tint: deepRed
                    ) {
                        showResetConfirm = true
                    }

                    sectionTitle("About")
                    infoRow(icon: "info.circle.fill", title: "Version", value: "1.0.0")
                }
                .padding(16)
            }

            if showResetConfirm {
                ZStack {
                    Color.black.opacity(0.65).ignoresSafeArea()

                    VStack(spacing: 14) {
                        Text("Reset Progress?")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundColor(creamWhite)
                        Text("This will delete all your progress, coins and purchases. This cannot be undone.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(creamWhite.opacity(0.7))
                            .multilineTextAlignment(.center)

                        HStack(spacing: 10) {
                            Button("Cancel") {
                                showResetConfirm = false
                            }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(creamWhite)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(Color.white.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button("Reset") {
                                resetAllProgress()
                                showResetConfirm = false
                            }
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(deepRed)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(18)
                    .background(Color(red: 0.1, green: 0.1, blue: 0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView {
                StorageService.shared.hasSeenOnboarding = true
                showOnboarding = false
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            SafariView(url: privacyPolicyURL)
                .ignoresSafeArea()
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(creamWhite)
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }

            Spacer()

            Text("SETTINGS")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(warmYellow)

            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        HStack {
            Text(text.uppercased())
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(creamWhite.opacity(0.85))
                .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
            Spacer()
        }
        .padding(.top, 4)
    }

    private func settingToggleRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon: icon, tint: warmYellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundColor(creamWhite)
                    .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
                Text(subtitle)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(creamWhite.opacity(0.85))
            }

            Spacer()

            Button {
                isOn.wrappedValue.toggle()
            } label: {
                ZStack(alignment: isOn.wrappedValue ? .trailing : .leading) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isOn.wrappedValue ? hotOrange : Color.white.opacity(0.18))
                        .frame(width: 56, height: 30)
                    Circle()
                        .fill(creamWhite)
                        .frame(width: 24, height: 24)
                        .padding(3)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func actionRow(icon: String, title: String, subtitle: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                iconBadge(icon: icon, tint: tint)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(creamWhite)
                        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(creamWhite.opacity(0.85))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(creamWhite.opacity(0.5))
            }
            .padding(12)
            .background(Color.black.opacity(0.35))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func infoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            iconBadge(icon: icon, tint: warmYellow)
            Text(title)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundColor(creamWhite)
                .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(creamWhite.opacity(0.9))
        }
        .padding(12)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private func iconBadge(icon: String, tint: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(tint)
            .frame(width: 38, height: 38)
            .background(tint.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func resetAllProgress() {
        let domain = Bundle.main.bundleIdentifier ?? ""
        UserDefaults.standard.removePersistentDomain(forName: domain)
        soundEnabled = true
        hapticEnabled = true
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        controller.preferredControlTintColor = UIColor(red: 0.96, green: 0.77, blue: 0.26, alpha: 1)
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
