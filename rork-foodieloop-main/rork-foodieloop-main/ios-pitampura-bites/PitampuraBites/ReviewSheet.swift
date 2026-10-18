//
//  ReviewSheet.swift
//  PitampuraBites
//
//  The one review surface in the app: food quality, vibe (up to 3), value
//  verdict, who was there, and an optional one-liner + photo. Saves a Visit
//  to AppState (all mock/local).
//

import SwiftUI
import PhotosUI

struct ReviewSheet: View {
    let shop: Shop
    /// Called after the visit is saved, e.g. to show a toast.
    let onSaved: () -> Void

    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var quality: FoodQuality?
    @State private var vibes: Set<Vibe> = []
    @State private var damage: Damage?
    @State private var tagged: Set<String> = []
    @State private var addedNames: [String] = []
    @State private var showAddPerson = false
    @State private var newPersonName = ""
    @State private var oneLiner = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var photoImage: Image?
    /// Down-scaled JPEG persisted with the visit on submit.
    @State private var photoData: Data?

    private var canPost: Bool { quality != nil }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                header
                qualityRow
                vibeRow
                damageRow
                tagRow
                oneLinerRow
                PrimaryButton(title: "post it", isEnabled: canPost, action: post)
            }
            .padding(24)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .presentationDragIndicator(.visible)
        .alert("Add someone", isPresented: $showAddPerson) {
            TextField("Name", text: $newPersonName)
            Button("Add") { addPerson() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Tag them in this review.")
        }
        .onChange(of: photoItem) { _, item in
            loadPhoto(from: item)
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("you're rating")
                .font(.system(size: 15))
                .foregroundStyle(Color.appTextSecondary)
            Text(shop.name)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white)
            HStack(spacing: 6) {
                Image(systemName: "mappin")
                    .font(.system(size: 13))
                Text(shop.locality)
                Text("•")
                Image(systemName: "storefront")
                    .font(.system(size: 13))
                Text(shop.category.lowercased())
            }
            .font(.system(size: 15))
            .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sections

    private var qualityRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("how's the food?")
            HStack(spacing: 10) {
                ForEach(FoodQuality.allCases) { option in
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(.spring(duration: 0.25)) { quality = option }
                    } label: {
                        Text(option.rawValue)
                            .font(.system(size: 16, weight: quality == option ? .semibold : .regular))
                            .foregroundStyle(quality == option ? .black : .white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(quality == option ? Color.lime : Color.appSurface, in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Food was \(option.rawValue)")
                    .accessibilityAddTraits(quality == option ? [.isSelected] : [])
                }
            }
        }
    }

    private var vibeRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("what's the vibe? (pick up to 3)")
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                spacing: 12
            ) {
                ForEach(Vibe.allCases) { vibe in
                    let isSelected = vibes.contains(vibe)
                    let atCap = !isSelected && vibes.count >= 3
                    Button {
                        guard !atCap else {
                            UINotificationFeedbackGenerator().notificationOccurred(.warning)
                            return
                        }
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(.spring(duration: 0.25)) {
                            if isSelected {
                                vibes.remove(vibe)
                            } else {
                                vibes.insert(vibe)
                            }
                        }
                    } label: {
                        Text(vibe.rawValue)
                            .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                            .foregroundStyle(isSelected ? .black : .white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(isSelected ? Color.hotPink : Color.appSurface, in: .capsule)
                            .opacity(atCap ? 0.4 : 1)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Vibe \(vibe.rawValue)")
                    .accessibilityAddTraits(isSelected ? [.isSelected] : [])
                }
            }
        }
    }

    private var damageRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("the damage? 💸")
            HStack(spacing: 10) {
                ForEach(Damage.allCases) { option in
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(.spring(duration: 0.25)) {
                            damage = damage == option ? nil : option
                        }
                    } label: {
                        Text(option.rawValue)
                            .font(.system(size: 14, weight: damage == option ? .semibold : .regular))
                            .foregroundStyle(damage == option ? .black : .white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(damage == option ? Color.lime : Color.appSurface, in: .capsule)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Value \(option.rawValue)")
                    .accessibilityAddTraits(damage == option ? [.isSelected] : [])
                }
            }
        }
    }

    private var tagRow: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionLabel("tag who was there (optional)")
            HStack(spacing: 18) {
                ForEach(Array(personNames.enumerated()), id: \.element) { index, name in
                    PersonTag(
                        name: name,
                        color: Self.tagPalette[index % Self.tagPalette.count].0,
                        textColor: Self.tagPalette[index % Self.tagPalette.count].1,
                        isTagged: tagged.contains(name)
                    ) {
                        if tagged.contains(name) {
                            tagged.remove(name)
                        } else {
                            tagged.insert(name)
                        }
                        UISelectionFeedbackGenerator().selectionChanged()
                    }
                }

                Button {
                    showAddPerson = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().strokeBorder(Color.appTextSecondary.opacity(0.5), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Add someone to tag")
            }
        }
    }

    private var oneLinerRow: some View {
        HStack(spacing: 12) {
            TextField("one liner or photo (optional)", text: $oneLiner)
                .font(.system(size: 16))
                .foregroundStyle(.white)

            if let image = photoImage {
                Button {
                    photoImage = nil
                    photoData = nil
                    photoItem = nil
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 40)
                        .clipShape(.rect(cornerRadius: 10))
                        .overlay(alignment: .topTrailing) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.white, .black.opacity(0.7))
                                .offset(x: 5, y: -5)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Remove photo")
            }

            PhotosPicker(selection: $photoItem, matching: .images) {
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.appTextSecondary)
            }
            .accessibilityLabel(photoImage == nil ? "Add photo" : "Change photo")
        }
        .padding(.horizontal, 18)
        .frame(height: 60)
        .glassPanel(in: .rect(cornerRadius: 18))
    }

    // MARK: - Helpers

    private var personNames: [String] {
        MockData.friends.map(\.name) + addedNames
    }

    private static let tagPalette: [(Color, Color)] = [
        (Color.lime, .black),
        (Color.hotPink, .black),
        (.white, .black),
        (Color.appSurfaceRaised, Color.appTextSecondary)
    ]

    private func addPerson() {
        let name = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        if !personNames.contains(name) {
            addedNames.append(name)
        }
        tagged.insert(name)
        UISelectionFeedbackGenerator().selectionChanged()
        newPersonName = ""
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundStyle(Color.appTextSecondary)
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task { @MainActor in
            let data = try? await item.loadTransferable(type: Data.self)
            guard let data, let uiImage = UIImage(data: data) else { return }
            photoImage = Image(uiImage: uiImage)
            photoData = uiImage.downscaledJPEGData(maxDimension: 800)
        }
    }

    // MARK: - Submission

    private func post() {
        guard let quality else { return }
        let visit = Visit(
            id: UUID(),
            shopID: shop.id,
            author: .user(
                displayName: appState.displayName.isEmpty ? "You" : appState.displayName
            ),
            quality: quality,
            vibes: Array(vibes),
            damage: damage,
            tagged: Array(tagged),
            quote: oneLiner.trimmingCharacters(in: .whitespacesAndNewlines),
            photoData: photoData,
            date: Date()
        )
        appState.addVisit(visit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSaved()
        dismiss()
    }
}

/// Circle with the person's two-letter initials and a check badge when tagged.
private struct PersonTag: View {
    let name: String
    let color: Color
    let textColor: Color
    let isTagged: Bool
    let toggle: () -> Void

    private var initials: String {
        String(name.split(separator: " ").first?.prefix(2) ?? name.prefix(2)).lowercased()
    }

    var body: some View {
        Button(action: toggle) {
            VStack(spacing: 6) {
                ZStack(alignment: .bottomTrailing) {
                    Text(initials)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(textColor)
                        .frame(width: 56, height: 56)
                        .background(color, in: .circle)

                    if isTagged {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.black)
                            .frame(width: 18, height: 18)
                            .background(.white, in: .circle)
                            .overlay(Circle().stroke(Color.appBackground, lineWidth: 2))
                    }
                }

                Text(name)
                    .font(.system(size: 13))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(isTagged ? "Untag" : "Tag") \(name)")
        .accessibilityAddTraits(isTagged ? [.isSelected] : [])
    }
}
