import SwiftUI

struct ContentView: View {
    @State private var appState: AppState = .loading

    enum AppState {
        case loading
        case onboarding
        case menu
    }

    var body: some View {
        switch appState {
        case .loading:
            LoadingView {
                withAnimation {
                    if StorageService.shared.hasSeenOnboarding {
                        appState = .menu
                    } else {
                        appState = .onboarding
                    }
                }
            }
        case .onboarding:
            OnboardingView {
                withAnimation {
                    appState = .menu
                }
            }
        case .menu:
            MainMenuView()
        }
    }
}
