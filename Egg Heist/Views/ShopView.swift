import SwiftUI

struct ShopView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ShopViewModel()

    private let warmYellow = Color(red: 0.96, green: 0.77, blue: 0.26)
    private let hotOrange = Color(red: 1.0, green: 0.48, blue: 0.0)
    private let darkBg = Color(red: 0.063, green: 0.063, blue: 0.063)
    private let creamWhite = Color(red: 1.0, green: 0.96, blue: 0.88)

    var body: some View {
        ZStack {
            GameBackgroundView().ignoresSafeArea()

            VStack(spacing: 0) {
                header

                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .foregroundColor(warmYellow)
                    Text("\(viewModel.coins)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(creamWhite)
                }
                .padding(.top, 8)

                Text("All items, upgrades and skins")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(creamWhite.opacity(0.9))
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.items) { item in
                            shopItemRow(item)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                if let msg = viewModel.purchaseMessage {
                    Text(msg)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundColor(warmYellow)
                        .shadow(color: .black.opacity(0.45), radius: 7, y: 2)
                        .padding(.vertical, 8)
                        .transition(.opacity)
                }
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
            Text("SHOP")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .foregroundColor(warmYellow)
            Spacer()
            Color.clear.frame(width: 38, height: 38)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func shopItemRow(_ item: ShopItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.icon)
                .font(.title2)
                .foregroundColor(warmYellow)
                .frame(width: 44, height: 44)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(item.name)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(creamWhite)
                        .shadow(color: .black.opacity(0.35), radius: 6, y: 2)
                    if item.maxLevel > 1 {
                        Text("Lv.\(item.currentLevel)/\(item.maxLevel)")
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(hotOrange)
                    }
                }
                Text(item.description)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(creamWhite.opacity(0.82))
            }

            Spacer()

            Button {
                viewModel.purchase(item)
            } label: {
                if item.isEquipped {
                    Text("EQUIPPED")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.green)
                        .frame(width: 80, height: 32)
                        .background(Color.green.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else if item.isOwned {
                    Text("EQUIP")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(warmYellow)
                        .frame(width: 80, height: 32)
                        .background(warmYellow.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 11))
                        Text("\(item.price)")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(width: 80, height: 32)
                    .background(warmYellow)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
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
