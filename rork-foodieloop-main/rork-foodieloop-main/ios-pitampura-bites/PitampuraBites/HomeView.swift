//
//  HomeView.swift
//  PitampuraBites
//
//  Home per the reference design: location + greeting header with avatar,
//  search field with a lime QR shortcut, the What's Poppin' hero carousel
//  (single centered card, 2 s auto-swipe), Mutuals visited, two promo tiles,
//  Hidden gems and Fresh on the map.
//

import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState

    let openShop: (Shop) -> Void
    var onOpenExplore: () -> Void = {}
    var onOpenCircle: () -> Void = {}
    var onOpenProfile: () -> Void = {}
    var onScanRequest: () -> Void = {}

    @State private var trendingPageID: String?
    @State private var isScrollIdle = true
    @State private var searchText = ""
    @State private var showAreaPicker = false
    @State private var showMap = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                header
                searchField
                whatsPoppin
                mutualsVisited
                promoTiles
                hiddenGems
                freshOnTheMap
            }
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            try? await Task.sleep(for: .seconds(0.9))
            appState.refreshFeed()
        }
        .background(Color.appBackground)
        .sheet(isPresented: $showAreaPicker) {
            AreaPickerSheet(selected: appState.location.displayLocation) {
                appState.location.setManualLocality($0)
            }
            .presentationDetents([.medium])
            .presentationBackground(Color.appBackground)
        }
        .sheet(isPresented: $showMap) {
            NearbyMapView(
                userCoordinate: appState.location.currentLocation?.coordinate,
                locationService: appState.location
            )
        }
    }

    // MARK: - Header

    /// Location line — always tappable to re-open the area picker. The fill
    /// pin shows when a fix resolved (GPS or manual), the hollow pin while
    /// still locating.
    private var locationRow: some View {
        Button {
            showAreaPicker = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: appState.location.status == .locating ? "location" : "location.fill")
                    .font(.system(size: 12))
                Text(appState.location.displayLocation)
                    .font(.system(size: 14, weight: .medium))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
            }
            .foregroundStyle(.white)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Choose your area")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            locationRow

            HStack(alignment: .center) {
                (Text("Hey ").foregroundStyle(.white)
                 + Text(appState.displayName.isEmpty ? "Explorer" : appState.displayName)
                    .foregroundStyle(Color.lime))
                    .font(.system(size: 30, weight: .bold))
                    .lineLimit(1)

                Spacer()

                Button {
                    onOpenProfile()
                } label: {
                    AvatarView(imageData: appState.avatarImageData, size: 48, showsRing: true)
                        .accessibilityLabel("Open your profile")
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, .screenMargin)
        .padding(.top, 12)
    }

    // MARK: - Search + QR shortcut

    private var searchResults: [Shop] {
        guard !searchText.isEmpty else { return [] }
        return MockData.shops.filter {
            $0.name.localizedStandardContains(searchText) || $0.category.localizedStandardContains(searchText)
        }
    }

    private var searchField: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.appTextSecondary)
                    TextField("Search nearby restaurants...", text: $searchText)
                        .autocorrectionDisabled()
                }
                .padding(.leading, 16)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .glassPanel(in: .capsule)

                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    onScanRequest()
                } label: {
                    Image(systemName: "qrcode")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 52, height: 52)
                        .background(Color.lime, in: .circle)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Scan shop QR")
            }
            .padding(.horizontal, .screenMargin)

            if !searchText.isEmpty {
                if searchResults.isEmpty {
                    Text("No matches for “\(searchText)”")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appTextSecondary)
                        .padding(.horizontal, .screenMargin)
                } else {
                    VStack(spacing: 2) {
                        ForEach(searchResults.prefix(4)) { shop in
                            Button {
                                openShop(shop)
                            } label: {
                                ShopRow(shop: shop)
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(.horizontal, .screenMargin)
                }
            }
        }
    }

    // MARK: - Section header builder

    private func sectionHeader(
        icon: String,
        title: String,
        subtitle: String? = nil,
        seeAllAction: (() -> Void)? = nil
    ) -> some View {
        HStack(alignment: .center) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(Color.lime)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11.5))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }
            Spacer()
            if let seeAllAction {
                Button {
                    seeAllAction()
                } label: {
                    HStack(spacing: 3) {
                        Text("See all")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("See all \(title)")
            }
        }
        .padding(.horizontal, .screenMargin)
    }

    // MARK: - What's Poppin'

    private var whatsPoppin: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                icon: "arrow.trending.up",
                title: "What's Poppin'",
                seeAllAction: onOpenExplore
            )

            ScrollView(.horizontal) {
                // Spacing equals the screen margin so the neighbouring card's
                // edge lands exactly at x = 0 — never visible in the margins.
                LazyHStack(spacing: .screenMargin) {
                    ForEach(MockData.trendingShops) { shop in
                        HeroCard(shop: shop)
                            .frame(width: whatsPoppinCardWidth)
                            .onTapGesture { openShop(shop) }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $trendingPageID)
            .contentMargins(.horizontal, .screenMargin, for: .scrollContent)
            .scrollIndicators(.hidden)
            .frame(height: 400)
            .onScrollPhaseChange { _, phase in
                // Pause the auto-swipe while the user is driving.
                isScrollIdle = (phase == .idle)
            }
            .task {
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(2))
                    guard isScrollIdle else { continue }
                    let shops = MockData.trendingShops
                    let current = shops.firstIndex { $0.id == trendingPageID } ?? 0
                    withAnimation(.spring(duration: 0.5)) {
                        trendingPageID = shops[(current + 1) % shops.count].id
                    }
                }
            }

            HStack(spacing: 6) {
                let currentIndex = MockData.trendingShops.firstIndex { $0.id == trendingPageID } ?? 0
                ForEach(0..<MockData.trendingShops.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentIndex ? Color.lime : Color.appSurfaceRaised)
                        .frame(width: index == currentIndex ? 18 : 6, height: 6)
                }
            }
            .frame(maxWidth: .infinity)
            .animation(.spring(duration: 0.3), value: trendingPageID)
        }
    }

    /// Exactly one card per screen width minus both margins — the next card
    /// never peeks in.
    private var whatsPoppinCardWidth: CGFloat {
        UIScreen.main.bounds.width - .screenMargin * 2
    }

    // MARK: - Mutuals visited

    private var mutualsVisited: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                icon: "person.2.fill",
                title: "Mutuals visited",
                seeAllAction: onOpenCircle
            )

            ScrollView(.horizontal) {
                LazyHStack(spacing: 14) {
                    ForEach(appState.recentFriendActivity(limit: 6)) { visit in
                        MutualCard(visit: visit) { shop in
                            openShop(shop)
                        }
                    }
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, .screenMargin, for: .scrollContent)
        }
    }

    // MARK: - Promo tiles

    private var promoTiles: some View {
        HStack(spacing: 12) {
            promoTile(
                title: "Try new",
                subtitle: "Discover trending spots near you",
                imageName: "jalebi_kulfi_falooda",
                accent: .lime,
                action: onOpenExplore
            )
            promoTile(
                title: "Drive-&-go",
                subtitle: "Grab and go, no wait!",
                imageName: "latte_rosetta_art",
                accent: .hotPink,
                action: { showMap = true }
            )
        }
        .padding(.horizontal, .screenMargin)
    }

    private func promoTile(
        title: String,
        subtitle: String,
        imageName: String,
        accent: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color.appTextSecondary)
                        .lineSpacing(1)
                        .multilineTextAlignment(.leading)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(accent == .lime ? .black : .white)
                        .frame(width: 28, height: 28)
                        .background(accent, in: .circle)
                }

                Color.clear
                    .overlay {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .allowsHitTesting(false)
                    }
                    .frame(width: 64)
                    .clipShape(.rect(cornerRadius: 14))
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .frame(height: 116)
            .background(Color.appSurface, in: .rect(cornerRadius: 20))
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(accent.opacity(0.55), lineWidth: 1.5)
            }
            .shadow(color: accent.opacity(0.25), radius: 14)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Hidden gems

    private var hiddenGems: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                icon: "sparkles",
                title: "Hidden gems",
                subtitle: "Handpicked spots you'll love",
                seeAllAction: onOpenExplore
            )

            ScrollView(.horizontal) {
                LazyHStack(spacing: 12) {
                    ForEach(MockData.hiddenGems) { shop in
                        GemCard(
                            shop: shop,
                            isSaved: appState.isSaved(shop.id),
                            toggleSaved: { appState.toggleSaved(shop.id) },
                            open: { openShop(shop) }
                        )
                        .frame(width: 148)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, .screenMargin, for: .scrollContent)
        }
    }

    // MARK: - Fresh on the map

    /// Nearest onboarded spots that aren't already trending up top, so this
    /// section always has something new as the user's position changes.
    private var freshShops: [Shop] {
        let sorted = MockData.shops.sorted {
            (appState.location.distanceMeters(to: $0.coordinate) ?? .greatestFiniteMagnitude)
                < (appState.location.distanceMeters(to: $1.coordinate) ?? .greatestFiniteMagnitude)
        }
        return Array(sorted.filter { !MockData.trendingShops.contains($0) }.prefix(2))
    }

    private var freshOnTheMap: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(
                icon: "location.fill",
                title: "Fresh on the map",
                subtitle: "New places. Just around you.",
                seeAllAction: { showMap = true }
            )

            VStack(spacing: 12) {
                ForEach(freshShops) { shop in
                    FreshCard(
                        shop: shop,
                        distance: appState.location.distanceMeters(to: shop.coordinate)
                    ) {
                        openShop(shop)
                    }
                }
            }
            .padding(.horizontal, .screenMargin)
        }
    }
}

// MARK: - Cards

/// A friend's latest visit, as a compact vertical card.
private struct MutualCard: View {
    let visit: Visit
    let openShop: (Shop) -> Void

    private var shop: Shop? { MockData.shop(id: visit.shopID) }

    var body: some View {
        Button {
            if let shop {
                openShop(shop)
            }
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 8) {
                    AuthorAvatarView(author: visit.author, size: 30)
                    Text(visit.author.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer()
                    Text(Self.shortTimeAgo(visit.date))
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(.bottom, 12)

                Color.appSurfaceRaised
                    .overlay {
                        Image(shop?.imageName ?? "papdi_chaat_bowl")
                            .resizable()
                            .scaledToFill()
                            .allowsHitTesting(false)
                    }
                    .frame(height: 124)
                    .clipShape(.rect(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 8) {
                    Text("at \(shop?.name ?? "a place")")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    QualityChip(quality: visit.quality, fontSize: 13)
                }
                .padding(.top, 12)
            }
            .padding(14)
            .frame(width: 232)
            .background(Color.appSurface, in: .rect(cornerRadius: 22))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(visit.author.name) thinks \(shop?.name ?? "a place") \(visit.quality.rawValue)")
    }

    private static func shortTimeAgo(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        switch seconds {
        case ..<60: return "now"
        case ..<3600: return "\(Int(seconds / 60))m ago"
        case ..<86400: return "\(Int(seconds / 3600))h ago"
        default: return "\(Int(seconds / 86400))d ago"
        }
    }
}

/// The large trending card: full-bleed photo, gradient, name + pink rating.
/// Color anchors the layout so the fill image can't inflate the frame.
private struct HeroCard: View {
    let shop: Shop

    var body: some View {
        Color.appSurface
            .overlay {
                Image(shop.imageName)
                    .resizable()
                    .scaledToFill()
                    .allowsHitTesting(false)
            }
            .overlay {
                LinearGradient(
                    colors: [.clear, .clear, .black.opacity(0.78)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(shop.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    HStack(spacing: 12) {
                        RatingBadge(rating: shop.rating, fontSize: 15)
                        Text(shop.priceText)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)
                        if shop.isOpenNow { OpenNowChip() }
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .clipShape(.rect(cornerRadius: 24))
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(shop.name), rating \(shop.rating) out of 5")
    }
}

/// A hidden-gem card: photo with rating + save heart overlaid, then name,
/// locality line and the pink pick pill.
private struct GemCard: View {
    let shop: Shop
    let isSaved: Bool
    let toggleSaved: () -> Void
    let open: () -> Void

    var body: some View {
        Button {
            open()
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Color.appSurfaceRaised
                    .overlay {
                        Image(shop.imageName)
                            .resizable()
                            .scaledToFill()
                            .allowsHitTesting(false)
                    }
                    .frame(height: 104)
                    .overlay(alignment: .topLeading) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.hotPink)
                            Text(String(format: "%.1f", shop.rating))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(.black.opacity(0.55), in: .capsule)
                        .padding(7)
                    }
                    .overlay(alignment: .topTrailing) {
                        Button {
                            toggleSaved()
                        } label: {
                            Image(systemName: isSaved ? "heart.fill" : "heart")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(isSaved ? Color.hotPink : .white)
                                .frame(width: 26, height: 26)
                                .background(.black.opacity(0.55), in: .circle)
                                .padding(7)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(isSaved ? "Remove \(shop.name) from saved" : "Save \(shop.name)")
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(shop.name)
                        .font(.system(size: 13.5, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(shop.category) · \(shop.locality)")
                        .font(.system(size: 10.5))
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)
                    Text(shop.gemPill)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.hotPink, in: .capsule)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            .background(Color.appSurface, in: .rect(cornerRadius: 18))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(shop.name), \(shop.gemPill)")
    }
}

/// A wide "Fresh on the map" row: photo left, details + live distance right,
/// lime View Details pill.
private struct FreshCard: View {
    let shop: Shop
    let distance: CLLocationDistance?
    let open: () -> Void

    var body: some View {
        Button {
            open()
        } label: {
            HStack(spacing: 0) {
                Color.appSurfaceRaised
                    .overlay {
                        Image(shop.imageName)
                            .resizable()
                            .scaledToFill()
                            .allowsHitTesting(false)
                    }
                    .frame(width: 124)
                    .clipShape(.rect)

                VStack(alignment: .leading, spacing: 6) {
                    Text(shop.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text("\(shop.category) · \(shop.locality)")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.appTextSecondary)
                        .lineLimit(1)

                    HStack(spacing: 10) {
                        RatingBadge(rating: shop.rating, fontSize: 12)
                        HStack(spacing: 3) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 10))
                            if let distance {
                                Text(LocationService.formatDistance(distance))
                            } else {
                                Text(shop.locality)
                            }
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.white.opacity(0.85))
                    }

                    Text("View Details  →")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 6)
                        .background(Color.lime, in: .capsule)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .frame(height: 112)
            .background(Color.appSurface, in: .rect(cornerRadius: 18))
            .clipShape(.rect(cornerRadius: 18))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View details for \(shop.name)")
    }
}
