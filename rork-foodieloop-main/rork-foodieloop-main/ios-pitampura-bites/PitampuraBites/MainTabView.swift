//
//  MainTabView.swift
//  PitampuraBites
//
//  Floating glass pill tab bar (icons only) with a raised lime Scan button
//  in the centre that opens the full-screen scanner.
//

import SwiftUI

enum MainTab: Hashable {
    case home, explore, circle, passport
}

struct MainTabView: View {
    @Environment(AppState.self) private var appState

    @State private var selectedTab: MainTab = .home
    @State private var showScan = false
    @State private var presentedShop: Shop?

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        openShop: openShop,
                        onOpenExplore: { selectedTab = .explore },
                        onOpenCircle: { selectedTab = .circle },
                        onOpenProfile: { selectedTab = .passport },
                        onScanRequest: { showScan = true }
                    )
                case .explore: ExploreView(openShop: openShop)
                case .circle: CircleView(openShop: openShop)
                case .passport: PassportView(openShop: openShop)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            tabBar
        }
        .background(Color.appBackground)
        .task { appState.location.requestCurrentLocality() }
        .fullScreenCover(isPresented: $showScan) {
            ScanView()
        }
        .fullScreenCover(item: $presentedShop) { shop in
            ShopDetailView(shop: shop)
        }
    }

    private func openShop(_ shop: Shop) {
        presentedShop = shop
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabItem(.home, activeIcon: "house.fill", inactiveIcon: "house", label: "Home")
            tabItem(.explore, activeIcon: "safari.fill", inactiveIcon: "safari", label: "Explore")
            scanButton
            tabItem(.circle, activeIcon: "person.2.fill", inactiveIcon: "person.2", label: "Circle")
            tabItem(.passport, activeIcon: "bookmark.fill", inactiveIcon: "bookmark", label: "Passport")
        }
        .frame(height: 60)
        .glassPanel(in: .capsule)
        .padding(.horizontal, 36)
        .padding(.bottom, 6)
    }

    private func tabItem(_ tab: MainTab, activeIcon: String, inactiveIcon: String, label: String) -> some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            withAnimation(.spring(duration: 0.3)) { selectedTab = tab }
        } label: {
            Image(systemName: selectedTab == tab ? activeIcon : inactiveIcon)
                .font(.system(size: 21, weight: .semibold))
                .foregroundStyle(selectedTab == tab ? Color.lime : .white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }

    private var scanButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showScan = true
        } label: {
            Image(systemName: "qrcode")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(.black)
                .frame(width: 50, height: 50)
                .background(Color.lime, in: .circle)
                .shadow(color: Color.lime.opacity(0.35), radius: 12)
                .frame(maxWidth: .infinity)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scan shop QR")
    }
}
