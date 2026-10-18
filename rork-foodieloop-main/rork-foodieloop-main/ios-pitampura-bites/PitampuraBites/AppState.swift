//
//  AppState.swift
//  PitampuraBites
//
//  Simulated session + persistence. Authentication is a placeholder:
//  nothing here talks to a real SMS or auth service.
//

import SwiftUI

@Observable
final class AppState {
    private enum Key {
        static let hasOnboarded = "pb.hasOnboarded"
        static let displayName = "pb.displayName"
        static let username = "pb.username"
        static let avatarImage = "pb.avatarImageData"
        static let visits = "pb.visits"
        static let savedShopIDs = "pb.savedShopIDs"
    }

    private let defaults = UserDefaults.standard

    /// Real device location for the home header; falls back to "Pitampura".
    let location = LocationService()

    // MARK: - Session (simulated)

    var hasOnboarded: Bool = false {
        didSet { defaults.set(hasOnboarded, forKey: Key.hasOnboarded) }
    }

    var displayName: String = "" {
        didSet { defaults.set(displayName, forKey: Key.displayName) }
    }

    var username: String = "" {
        didSet { defaults.set(username, forKey: Key.username) }
    }

    /// User's profile photo, stored as JPEG data. nil = default silhouette.
    var avatarImageData: Data? {
        didSet { defaults.set(avatarImageData, forKey: Key.avatarImage) }
    }

    // MARK: - Content

    /// Reviews and visits the user has submitted.
    var visits: [Visit] = [] {
        didSet { persistVisits() }
    }

    /// Mock "live" friend visits that pull-to-refresh fetches.
    private var liveFriendVisits: [Visit] = []

    /// Shops the user saved.
    var savedShopIDs: Set<String> = [] {
        didSet { defaults.set(Array(savedShopIDs), forKey: Key.savedShopIDs) }
    }

    init() {
        hasOnboarded = defaults.bool(forKey: Key.hasOnboarded)
        displayName = defaults.string(forKey: Key.displayName) ?? ""
        username = defaults.string(forKey: Key.username) ?? ""
        avatarImageData = defaults.data(forKey: Key.avatarImage)
        savedShopIDs = Set(defaults.stringArray(forKey: Key.savedShopIDs) ?? [])
        if let data = defaults.data(forKey: Key.visits) {
            visits = (try? JSONDecoder().decode([Visit].self, from: data)) ?? []
        }
    }

    // MARK: - Actions

    func toggleSaved(_ shopID: String) {
        if savedShopIDs.contains(shopID) {
            savedShopIDs.remove(shopID)
        } else {
            savedShopIDs.insert(shopID)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func isSaved(_ shopID: String) -> Bool {
        savedShopIDs.contains(shopID)
    }

    /// Adds the user's review/visit and keeps the feed sorted newest first.
    func addVisit(_ visit: Visit) {
        visits.insert(visit, at: 0)
        visits.sort { $0.date > $1.date }
    }

    func visits(forShop shopID: String) -> [Visit] {
        visits.filter { $0.shopID == shopID }
    }

    /// Everything the Circle feed shows: friends' seed visits + user's own.
    var circleFeed: [Visit] {
        (liveFriendVisits + MockData.seedVisits + visits).sorted { $0.date > $1.date }
    }

    /// Newest friend activity, used by Home's "Mutuals visited" rail.
    func recentFriendActivity(limit: Int) -> [Visit] {
        Array((liveFriendVisits + MockData.seedVisits)
            .sorted { $0.date > $1.date }
            .prefix(limit))
    }

    /// Mock pull-to-refresh: a friend "checks in" somewhere new.
    func refreshFeed() {
        guard let friend = MockData.friends.randomElement(),
              let shop = MockData.shops.randomElement() else { return }
        let quotes = [
            "The paneer roll here is dangerous.",
            "Went for one coffee. Stayed for three.",
            "Sunday breakfast sorted.",
            "That chutney deserves an award.",
            "Corner seat, great playlist, zero regrets.",
            "Momos beat everything else today."
        ]
        let visit = Visit(
            id: UUID(),
            shopID: shop.id,
            author: .friend(friend),
            quality: FoodQuality.allCases.randomElement()!,
            vibes: Array(Vibe.allCases.shuffled().prefix(Int.random(in: 1...2))),
            damage: Damage.allCases.randomElement(),
            tagged: [],
            quote: quotes.randomElement()!,
            photoData: nil,
            date: Date()
        )
        liveFriendVisits.append(visit)
    }

    func shop(for visit: Visit) -> Shop? {
        MockData.shop(id: visit.shopID)
    }

    /// Clears the simulated session (Sign out on Passport).
    func signOut() {
        hasOnboarded = false
        displayName = ""
        username = ""
        avatarImageData = nil
        visits = []
        savedShopIDs = []
    }

    private func persistVisits() {
        if let data = try? JSONEncoder().encode(visits) {
            defaults.set(data, forKey: Key.visits)
        }
    }
}
