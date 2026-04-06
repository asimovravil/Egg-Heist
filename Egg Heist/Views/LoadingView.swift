import SwiftUI

struct LoadingView: View {
    @State private var progress: CGFloat = 0
    let onFinished: () -> Void

    private let warmYellow = Color(red: 0.96, green: 0.77, blue: 0.26)
    private let hotOrange = Color(red: 1.0, green: 0.48, blue: 0.0)

    var body: some View {
        ZStack {
            GameBackgroundView().ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 280)
                    .shadow(color: hotOrange.opacity(0.45), radius: 14)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.18))
                            .frame(height: 10)
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [warmYellow, hotOrange], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * progress, height: 10)
                    }
                }
                .frame(height: 10)
                .padding(.horizontal, 44)

                Spacer()
            }
        }
        .onAppear {
            progress = 0
            withAnimation(.linear(duration: 2.8)) {
                progress = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                onFinished()
            }
        }
    }
}
