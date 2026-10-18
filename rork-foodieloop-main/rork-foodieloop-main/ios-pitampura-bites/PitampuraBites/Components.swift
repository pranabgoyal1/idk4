//
//  Components.swift
//  PitampuraBites
//
//  Reusable building blocks shared across tabs.
//

import SwiftUI

/// Quiet section heading, e.g. "Hidden gems".
struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Plain row for a shop: round photo, name, grey subtitle, rating on the right.
/// Used for lists without card backgrounds.
struct ShopRow: View {
    let shop: Shop
    var showsChevron = true
    var showsRating = true

    var body: some View {
        HStack(spacing: 14) {
            Image(shop.imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(.circle)

            VStack(alignment: .leading, spacing: 3) {
                Text(shop.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text(shop.subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            if showsRating {
                RatingBadge(rating: shop.rating)
            }
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.6))
            }
        }
        .contentShape(.rect)
    }
}

/// A short grey line of copy, used for empty states.
struct EmptyHint: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundStyle(Color.appTextSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Pink chip with the review's food-quality word ("slaps", "goated"…).
/// Pink = ratings/social per the accent contract.
struct QualityChip: View {
    let quality: FoodQuality
    var fontSize: CGFloat = 14

    var body: some View {
        Text(quality.rawValue)
            .font(.system(size: fontSize, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.hotPink)
            .clipShape(.capsule)
    }
}

/// Small lime pill marking "open now".
struct OpenNowChip: View {
    var body: some View {
        Text("Open now")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.lime)
            .clipShape(.capsule)
    }
}

/// Attaches an onTapGesture only when the picker should be offered, so the
/// profile preview row stays inert when a GPS fix already resolved the area.
struct AreaTapModifier: ViewModifier {
    let showPicker: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        if showPicker {
            content.onTapGesture(perform: action)
        } else {
            content
        }
    }
}

/// Quiet sheet for picking the browsed area when GPS can't resolve
/// (e.g. the sandboxed preview has no location backend).
struct AreaPickerSheet: View {
    let selected: String
    let onPick: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Choose your area")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 24)

            VStack(spacing: 0) {
                ForEach(MockData.localities, id: \.self) { item in
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        onPick(item)
                        dismiss()
                    } label: {
                        HStack {
                            Text(item)
                                .font(.system(size: 17, weight: .medium))
                                .foregroundStyle(item == selected ? Color.lime : .white)
                            Spacer()
                            if item == selected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color.lime)
                            }
                        }
                        .padding(.vertical, 16)
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Set area to \(item)")

                    if item != MockData.localities.last {
                        Divider().overlay(Color.appDivider)
                    }
                }
            }

            Text("Live location isn't available in this preview — pick the area you want to browse. On a real device this updates automatically.")
                .font(.system(size: 13))
                .foregroundStyle(Color.appTextSecondary.opacity(0.75))
                .lineSpacing(3)

            Spacer()
        }
        .padding(24)
        .background(Color.appBackground)
    }
}
