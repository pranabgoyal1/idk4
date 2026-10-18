//
//  PassportView.swift
//  PitampuraBites
//
//  Profile: avatar, handle, stats, saved places, visit history and
//  a simulated sign-out.
//

import SwiftUI
import PhotosUI

struct PassportView: View {
    @Environment(AppState.self) private var appState

    let openShop: (Shop) -> Void

    @State private var showEditProfile = false
    @State private var showSignOutConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                profileHeader
                statsRow
                savedPlaces
                visitHistory
                signOutButton
            }
            .padding(.horizontal, .screenMargin)
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
        .background(Color.appBackground)
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet()
                .presentationDetents([.medium, .large])
                .presentationBackground(Color.appBackground)
        }
        .confirmationDialog(
            "Sign out of the demo account?",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("Sign out", role: .destructive) { appState.signOut() }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Sections

    private var profileHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            PageTitle("Passport")
                .padding(.top, 12)

            HStack(spacing: 18) {
                Button {
                    showEditProfile = true
                } label: {
                    AvatarView(imageData: appState.avatarImageData, size: 84, showsRing: true)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Edit profile photo")

                VStack(alignment: .leading, spacing: 4) {
                    Text(appState.displayName.isEmpty ? "Explorer" : appState.displayName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    Text("@\(appState.username)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.lime)
                    Text(appState.location.displayLocation)
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appTextSecondary)
                }

                Spacer()
            }
        }
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatTile(title: "Visits", value: appState.visits.count)
            StatTile(title: "Reviews", value: appState.visits.count)
            StatTile(title: "Saved", value: appState.savedShopIDs.count)
        }
    }

    private var savedPlaces: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Saved places")
                .padding(.bottom, 8)

            let saved = MockData.shops.filter { appState.savedShopIDs.contains($0.id) }
            if saved.isEmpty {
                EmptyHint(text: "Tap the heart on a shop to keep it here.")
            } else {
                ForEach(saved) { shop in
                    Button { openShop(shop) } label: {
                        ShopRow(shop: shop)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var visitHistory: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: "Your visits")
                .padding(.bottom, 8)

            if appState.visits.isEmpty {
                EmptyHint(text: "Review a place and your visit history will appear here.")
            } else {
                ForEach(appState.visits) { visit in
                    MyVisitRow(visit: visit)
                        .padding(.vertical, 8)
                    Divider().overlay(Color.appDivider)
                }
            }
        }
    }

    private var signOutButton: some View {
        Button {
            showSignOutConfirm = true
        } label: {
            Text("Sign out")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .glassPanel(in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}

private struct StatTile: View {
    let title: String
    let value: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .glassPanel(in: .rect(cornerRadius: 20))
    }
}

/// Compact summary of the user's own visit.
private struct MyVisitRow: View {
    let visit: Visit

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(shopName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                QualityChip(quality: visit.quality, fontSize: 14)
            }
            if !visit.quote.isEmpty {
                Text("“\(visit.quote)”")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appTextSecondary)
            }
            HStack(spacing: 8) {
                Text(RelativeDateTimeFormatter().localizedString(for: visit.date, relativeTo: Date()))
                if !visit.tagged.isEmpty {
                    Text("· with \(visit.tagged.joined(separator: ", "))")
                }
            }
            .font(.system(size: 12))
            .foregroundStyle(Color.appTextSecondary.opacity(0.7))
        }
    }

    private var shopName: String {
        MockData.shop(id: visit.shopID)?.name ?? "A place"
    }
}

/// Edit display name + photo in place.
private struct EditProfileSheet: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var avatarImageData: Data?
    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Edit profile")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 24)

            TextField("Display name", text: $name)
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 54)
                .glassPanel(in: .rect(cornerRadius: 18))

            AvatarView(imageData: avatarImageData, size: 110, showsRing: true)
                .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 15, weight: .semibold))
                        Text(avatarImageData == nil ? "Upload photo" : "Change photo")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .glassPanel(in: .capsule)
                }
                .buttonStyle(.plain)

                if avatarImageData != nil {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(duration: 0.3)) { avatarImageData = nil }
                    } label: {
                        Text("Remove")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.appTextSecondary)
                            .padding(.horizontal, 20)
                            .frame(height: 48)
                            .glassPanel(in: .capsule)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)

            Spacer()

            PrimaryButton(title: "Save changes") {
                if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                    appState.displayName = name
                }
                appState.avatarImageData = avatarImageData
                dismiss()
            }
        }
        .padding(24)
        .background(Color.appBackground)
        .onAppear {
            name = appState.displayName
            avatarImageData = appState.avatarImageData
        }
        .onChange(of: photoItem) { _, item in
            loadPhoto(from: item)
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task { @MainActor in
            let data = try? await item.loadTransferable(type: Data.self)
            guard let data, let image = UIImage(data: data) else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            avatarImageData = image.downscaledJPEGData(maxDimension: 640)
        }
    }
}
