//
//  ShopDetailView.swift
//  PitampuraBites
//
//  Full-screen shop page: hero photo, key facts, friends' visits and
//  the quick review entry point. Owns the whole bottom edge (no tab bar).
//

import SwiftUI

struct ShopDetailView: View {
    let shop: Shop

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var showReviewSheet = false
    @State private var showReviewSavedToast = false

    private var friendsVisits: [Visit] {
        appState.circleFeed.filter { $0.shopID == shop.id }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    facts
                    friendVisits
                    Spacer(minLength: 60)
                }
            }
            .scrollIndicators(.hidden)

            PrimaryButton(title: "Review your visit", systemImage: "star.bubble") {
                showReviewSheet = true
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            .background(
                LinearGradient(
                    colors: [.clear, Color.appBackground.opacity(0.9)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
                .allowsHitTesting(false),
                alignment: .bottom
            )
        }
        .background(Color.appBackground)
        .ignoresSafeArea(edges: .top)
        .overlay(alignment: .top) {
            if showReviewSavedToast {
                ReviewSavedToast()
                    .padding(.top, 64)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showReviewSheet) {
            ReviewSheet(shop: shop) {
                withAnimation(.spring(duration: 0.4)) { showReviewSavedToast = true }
                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation { showReviewSavedToast = false }
                }
            }
            .presentationDetents([.large])
            .presentationBackground(Color.appBackground)
        }
    }

    // MARK: - Sections

    private var hero: some View {
        ZStack(alignment: .topLeading) {
            Color.appSurface
                .frame(height: 320)

            Image(shop.imageName)
                .resizable()
                .scaledToFill()
                .frame(height: 320)
                .clipped()
                .allowsHitTesting(false)

            LinearGradient(
                colors: [Color.appBackground.opacity(0.55), .clear, .clear, Color.appBackground.opacity(0.35)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 320)
            .allowsHitTesting(false)

            HStack {
                closeButton
                Spacer()
                saveButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 54)
        }
        .frame(height: 320)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "chevron.left")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .glassPanel(in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Back")
    }

    private var saveButton: some View {
        Button {
            appState.toggleSaved(shop.id)
        } label: {
            Image(systemName: appState.isSaved(shop.id) ? "heart.fill" : "heart")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(appState.isSaved(shop.id) ? Color.hotPink : .white)
                .frame(width: 38, height: 38)
                .glassPanel(in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(appState.isSaved(shop.id) ? "Remove from saved" : "Save place")
    }

    private var facts: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(shop.name)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)

            HStack(spacing: 12) {
                RatingBadge(rating: shop.rating, fontSize: 16)
                Text("\(shop.category) · \(shop.priceText)")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appTextSecondary)
                if shop.isOpenNow { OpenNowChip() }
            }

            Text(shop.blurb)
                .font(.system(size: 15))
                .foregroundStyle(Color.appTextSecondary)
                .lineSpacing(4)

            HStack(spacing: 10) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.lime)
                Text(shop.signatureDish)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .glassPanel(in: .capsule)
        }
        .padding(.horizontal, .screenMargin)
    }

    @ViewBuilder
    private var friendVisits: some View {
        if !friendsVisits.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                SectionHeader(title: "What friends said")
                    .padding(.bottom, 10)

                ForEach(friendsVisits) { visit in
                    HStack(alignment: .top, spacing: 12) {
                        AuthorAvatarView(author: visit.author, size: 40)
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(visit.author.name)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                Spacer()
                                QualityChip(quality: visit.quality, fontSize: 13)
                            }
                            if !visit.quote.isEmpty {
                                Text("“\(visit.quote)”")
                                    .font(.system(size: 14))
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                            if !visit.vibes.isEmpty {
                                Text(visit.vibes.map(\.rawValue).joined(separator: " · "))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.hotPink)
                            }

                            if let photo = visit.photo {
                                // Color anchor keeps the fill photo from
                                // inflating the row layout.
                                Color.appSurfaceRaised
                                    .frame(height: 150)
                                    .frame(maxWidth: .infinity)
                                    .overlay {
                                        Image(uiImage: photo)
                                            .resizable()
                                            .scaledToFill()
                                            .allowsHitTesting(false)
                                    }
                                    .clipShape(.rect(cornerRadius: 14))
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
            }
            .padding(.horizontal, .screenMargin)
        }
    }
}

private struct ReviewSavedToast: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
            Text("Review saved")
        }
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(.black)
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(Color.lime, in: .capsule)
        .shadow(color: .black.opacity(0.4), radius: 12)
    }
}
