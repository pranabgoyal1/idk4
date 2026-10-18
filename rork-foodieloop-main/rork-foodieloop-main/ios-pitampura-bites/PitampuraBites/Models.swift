//
//  Models.swift
//  PitampuraBites
//
//  Core domain types. Kept free of UI so a real backend can replace
//  MockData later without touching views.
//

import Foundation
import UIKit
import CoreLocation

/// A food place (restaurant or street stall).
struct Shop: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let category: String
    let locality: String
    /// 1 = ₹, 2 = ₹₹, 3 = ₹₹₹
    let priceLevel: Int
    let rating: Double
    /// Bundled image asset name.
    let imageName: String
    let signatureDish: String
    let blurb: String
    let isOpenNow: Bool
    let tags: [String]
    /// Real-world position: drives distances, map pins and the 200 m scan radius.
    let latitude: Double
    let longitude: Double
    /// Pink pick pill shown on Home's "Hidden gems" cards.
    var gemPill: String = "Must Visit"

    var priceText: String {
        String(repeating: "₹", count: priceLevel)
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// Payload encoded on the outlet's printed QR code.
    var qrPayload: String { "pitampurabites://shop/\(id)" }

    /// e.g. "Momos · Pitampura"
    var subtitle: String {
        "\(category) · \(locality)"
    }
}

/// A friend in the user's circle.
struct Friend: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let avatarImageName: String
}

/// Who wrote a visit/review.
enum VisitAuthor: Hashable, Codable {
    case friend(Friend)
    /// The signed-in user's avatar lives in AppState, not on the visit.
    case user(displayName: String)

    var name: String {
        switch self {
        case .friend(let friend): return friend.name
        case .user(let displayName): return displayName
        }
    }

    /// Bundled avatar asset name; the user's avatar is uploaded data instead.
    var avatarImageName: String? {
        switch self {
        case .friend(let friend): return friend.avatarImageName
        case .user: return nil
        }
    }
}

/// How the food hit, on the app's four-word scale. Maps onto a numeric
/// rating for aggregate displays.
enum FoodQuality: String, CaseIterable, Identifiable, Codable {
    case mid, decent, slaps, goated

    var id: String { rawValue }

    var rating: Double {
        switch self {
        case .mid: return 2.5
        case .decent: return 3.5
        case .slaps: return 4.5
        case .goated: return 5.0
        }
    }
}

/// Vibe tags picked alongside a review. At most three per review.
enum Vibe: String, CaseIterable, Identifiable, Codable {
    case worthTheHype = "worth the hype"
    case lateNight = "late night"
    case hugePortions = "huge portions"
    case chatpata
    case underratedAF = "underrated af"
    case overrated

    var id: String { rawValue }
}

/// Value-for-money verdict.
enum Damage: String, CaseIterable, Identifiable, Codable {
    case stealDeal = "steal deal"
    case wellSpent = "₹ well spent"
    case overpricedFR = "overpriced fr"

    var id: String { rawValue }
}

/// One reviewed visit to a shop.
struct Visit: Identifiable, Hashable, Codable {
    let id: UUID
    let shopID: String
    let author: VisitAuthor
    let quality: FoodQuality
    var vibes: [Vibe]
    var damage: Damage?
    /// Names of people tagged as being there (friends or ad-hoc).
    var tagged: [String]
    /// Optional one-liner; empty when the review is chips-only.
    let quote: String
    /// Optional down-scaled JPEG of the attached photo.
    let photoData: Data?
    let date: Date

    /// Numeric rating derived from the quality word, for aggregates.
    var rating: Double { quality.rating }

    /// Decoded photo for display, or nil when absent/corrupt.
    var photo: UIImage? {
        photoData.flatMap(UIImage.init(data:))
    }
}
