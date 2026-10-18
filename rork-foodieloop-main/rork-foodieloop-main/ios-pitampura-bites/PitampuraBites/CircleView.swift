//
//  CircleView.swift
//  PitampuraBites
//
//  Minimal social feed: one plain row per visit — avatar, "Riya at …",
//  a short quote, pink rating and a small food thumbnail.
//

import SwiftUI

struct CircleView: View {
    @Environment(AppState.self) private var appState

    let openShop: (Shop) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                PageTitle("Circle")
                    .padding(.top, 12)

                Text("Friends. Food. A more delicious you.")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appTextSecondary)
                    .padding(.bottom, 16)

                LazyVStack(spacing: 0) {
                    ForEach(appState.circleFeed) { visit in
                        VisitRow(visit: visit) { shop in
                            openShop(shop)
                        }
                        if visit.id != appState.circleFeed.last?.id {
                            Divider()
                                .overlay(Color.appDivider)
                        }
                    }
                }
            }
            .padding(.horizontal, .screenMargin)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .refreshable {
            try? await Task.sleep(for: .seconds(0.9))
            appState.refreshFeed()
        }
        .background(Color.appBackground)
    }
}

private struct VisitRow: View {
    let visit: Visit
    let openShop: (Shop) -> Void

    private var relativeDate: String {
        RelativeDateTimeFormatter().localizedString(for: visit.date, relativeTo: Date())
    }

    var body: some View {
        Button {
            if let shop = MockData.shop(id: visit.shopID) {
                openShop(shop)
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                AuthorAvatarView(author: visit.author, size: 46)

                VStack(alignment: .leading, spacing: 5) {
                    Text("\(visit.author.name) at \(shopName)")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)

                    if !visit.quote.isEmpty {
                        Text("“\(visit.quote)”")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.leading)
                    }

                    HStack(spacing: 10) {
                        QualityChip(quality: visit.quality, fontSize: 14)
                        Text(relativeDate)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appTextSecondary.opacity(0.7))
                    }
                }

                Spacer()

                Image(shopImageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 66, height: 66)
                    .clipShape(.rect(cornerRadius: 14))
            }
            .padding(.vertical, 14)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(visit.author.name) thinks \(shopName) \(visit.quality.rawValue)")
    }

    private var shopName: String {
        MockData.shop(id: visit.shopID)?.name ?? "a place"
    }

    private var shopImageName: String {
        MockData.shop(id: visit.shopID)?.imageName ?? "papdi_chaat_bowl"
    }
}
