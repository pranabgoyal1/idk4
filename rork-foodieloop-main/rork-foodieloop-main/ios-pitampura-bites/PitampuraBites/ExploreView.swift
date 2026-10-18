//
//  ExploreView.swift
//  PitampuraBites
//
//  Search, one row of categories, filters behind a single icon,
//  and a spacious results list.
//

import SwiftUI

struct ExploreView: View {
    let openShop: (Shop) -> Void

    @State private var searchText = ""
    @State private var category = "All"
    @State private var locality: String?
    @State private var maxPriceLevel: Int?
    @State private var showFilters = false

    private var results: [Shop] {
        MockData.shops.filter { shop in
            let matchesSearch = searchText.isEmpty
                || shop.name.localizedStandardContains(searchText)
                || shop.category.localizedStandardContains(searchText)
                || shop.signatureDish.localizedStandardContains(searchText)
            let matchesCategory = category == "All"
                || shop.category == category
                || (category == "Cafes" && shop.category == "Cafe")
            let matchesLocality = locality == nil || shop.locality == locality
            let matchesPrice = maxPriceLevel == nil || shop.priceLevel <= maxPriceLevel!
            return matchesSearch && matchesCategory && matchesLocality && matchesPrice
        }
    }

    private var activeFilterCount: Int {
        (locality != nil ? 1 : 0) + (maxPriceLevel != nil ? 1 : 0)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageTitle("Explore")
                    .padding(.top, 12)

                searchRow
                categoryRow
                resultsList
            }
            .padding(.horizontal, .screenMargin)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .sheet(isPresented: $showFilters) {
            FilterSheet(locality: $locality, maxPriceLevel: $maxPriceLevel)
                .presentationDetents([.medium])
                .presentationBackground(Color.appBackground)
        }
    }

    private var searchRow: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color.appTextSecondary)
                TextField("Search food or places", text: $searchText)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .glassPanel(in: .rect(cornerRadius: 18))

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showFilters = true
            } label: {
                Image(systemName: activeFilterCount > 0 ? "line.3.horizontal.decrease.circle.fill" : "slider.horizontal.3")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(activeFilterCount > 0 ? Color.lime : Color.appTextSecondary)
                    .frame(width: 50, height: 50)
                    .glassPanel(in: .rect(cornerRadius: 18))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Filters")
        }
    }

    /// Plain text categories, lime underline on the selected one.
    private var categoryRow: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 24) {
                ForEach(MockData.categories, id: \.self) { item in
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(.spring(duration: 0.3)) { category = item }
                    } label: {
                        VStack(spacing: 6) {
                            Text(item)
                                .font(.system(size: 15, weight: category == item ? .semibold : .regular))
                                .foregroundStyle(category == item ? Color.lime : Color.appTextSecondary)
                            Capsule()
                                .fill(category == item ? Color.lime : .clear)
                                .frame(width: 20, height: 2)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
        .scrollIndicators(.hidden)
    }

    private var resultsList: some View {
        VStack(spacing: 2) {
            if results.isEmpty {
                EmptyHint(text: "Nothing matches \"\(searchText)\" yet.")
                    .padding(.vertical, 32)
            }
            ForEach(results) { shop in
                Button {
                    openShop(shop)
                } label: {
                    ExploreRow(shop: shop)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 10)
            }
        }
    }
}

/// Roomier explore row: rounded-square photo, name, subtitle, rating.
private struct ExploreRow: View {
    let shop: Shop

    var body: some View {
        HStack(spacing: 16) {
            Image(shop.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(.rect(cornerRadius: 18))

            VStack(alignment: .leading, spacing: 4) {
                Text(shop.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Text("\(shop.category) · \(shop.priceText)")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            RatingBadge(rating: shop.rating)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appTextSecondary.opacity(0.6))
        }
        .contentShape(.rect)
    }
}

/// Locality + price filters, presented as a compact sheet.
private struct FilterSheet: View {
    @Binding var locality: String?
    @Binding var maxPriceLevel: Int?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            StepHeader()

            VStack(alignment: .leading, spacing: 12) {
                filterLabel("Locality")
                HStack(spacing: 10) {
                    TagChip(label: "Anywhere", isSelected: locality == nil) { locality = nil }
                    ForEach(MockData.localities, id: \.self) { item in
                        TagChip(label: item, isSelected: locality == item) { locality = item }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                filterLabel("Budget")
                HStack(spacing: 10) {
                    TagChip(label: "Any", isSelected: maxPriceLevel == nil) { maxPriceLevel = nil }
                    ForEach(1...3, id: \.self) { level in
                        TagChip(label: String(repeating: "₹", count: level), isSelected: maxPriceLevel == level) { maxPriceLevel = level }
                    }
                }
            }

            Spacer()

            PrimaryButton(title: "Show places") { dismiss() }
        }
        .padding(24)
        .background(Color.appBackground)
    }

    private func filterLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.appTextSecondary)
            .textCase(.uppercase)
    }
}

private struct StepHeader: View {
    var body: some View {
        Text("Filters")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
    }
}
