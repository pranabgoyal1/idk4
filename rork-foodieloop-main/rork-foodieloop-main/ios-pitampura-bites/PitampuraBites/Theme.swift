//
//  Theme.swift
//  PitampuraBites
//
//  Design tokens for the dark, neon-accented visual system.
//

import SwiftUI

extension Color {
    /// Near-black app canvas.
    static let appBackground = Color(hex: 0x101113)
    /// Elevated card and control surface.
    static let appSurface = Color(hex: 0x202125)
    /// Raised surface used for inputs and pressed states.
    static let appSurfaceRaised = Color(hex: 0x2A2B31)
    /// Secondary text.
    static let appTextSecondary = Color(hex: 0xA3A6AD)
    static let appDivider = Color.white.opacity(0.08)
    /// Primary accent: neon lime. Selected states, primary actions, scan indicators.
    static let lime = Color(hex: 0xC8FF28)
    /// Secondary accent: hot pink. Ratings and social elements.
    static let hotPink = Color(hex: 0xF72585)

    /// Creates a color from a 24-bit hex literal.
    init(hex: UInt) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
    }
}

/// Standard screen margin (24pt) for this design.
extension CGFloat {
    static let screenMargin: CGFloat = 24
}

/// Large bold page title, e.g. "Explore".
struct PageTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(.system(size: 34, weight: .bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Lime filled primary call-to-action button.
struct PrimaryButton: View {
    let title: String
    var systemImage: String?
    var isEnabled = true
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            action()
        } label: {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundStyle(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isEnabled ? Color.lime : Color.appSurfaceRaised)
            .clipShape(.rect(cornerRadius: 18))
            .opacity(isEnabled ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}

/// Small pink star with a numeric rating, used everywhere ratings appear.
struct RatingBadge: View {
    let rating: Double
    var fontSize: CGFloat = 15

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: fontSize - 3, weight: .bold))
            Text(String(format: "%.1f", rating))
                .font(.system(size: fontSize, weight: .bold, design: .rounded))
        }
        .foregroundStyle(Color.hotPink)
    }
}

/// Selectable tag chip. Selected chips use lime, unselected stay quiet grey on surface.
struct TagChip: View {
    let label: String
    var isSelected = false
    var action: (() -> Void)?

    var body: some View {
        Button {
            UISelectionFeedbackGenerator().selectionChanged()
            action?()
        } label: {
            Text(label)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .black : Color.appTextSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .chipSurface(isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }
}

/// Circular avatar with an optional lime ring. Renders an uploaded photo,
/// a bundled asset, or an Instagram-style person silhouette as the default.
struct AvatarView: View {
    var imageName: String? = nil
    var imageData: Data? = nil
    var size: CGFloat = 44
    var showsRing = false

    init(imageName: String? = nil, imageData: Data? = nil, size: CGFloat = 44, showsRing: Bool = false) {
        self.imageName = imageName
        self.imageData = imageData
        self.size = size
        self.showsRing = showsRing
    }

    var body: some View {
        avatarImage
            .frame(width: size, height: size)
            .background(Color.appSurface)
            .clipShape(.circle)
            .overlay {
                if showsRing {
                    Circle().strokeBorder(Color.lime, lineWidth: 2)
                }
            }
            .accessibilityLabel("Profile photo")
    }

    @ViewBuilder
    private var avatarImage: some View {
        if let data = imageData, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill()
        } else if let imageName, let image = UIImage(named: imageName) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            ZStack {
                Circle().fill(Color.appSurfaceRaised)
                Image(systemName: "person.fill")
                    .font(.system(size: size * 0.42, weight: .medium))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }
}

/// Avatar for a visit author: friends use bundled portraits, the user's
/// photo comes from AppState (or the default silhouette).
struct AuthorAvatarView: View {
    let author: VisitAuthor
    var size: CGFloat = 44
    var showsRing = false

    @Environment(AppState.self) private var appState

    var body: some View {
        switch author {
        case .friend(let friend):
            AvatarView(imageName: friend.avatarImageName, size: size, showsRing: showsRing)
        case .user:
            AvatarView(imageData: appState.avatarImageData, size: size, showsRing: showsRing)
        }
    }
}

extension View {
    /// iOS 26 liquid glass with an ultraThin material fallback on older OSes.
    @ViewBuilder
    func glassPanel<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: shape)
        } else {
            self.background(shape.fill(.ultraThinMaterial))
        }
    }

    /// Chip surface: lime fill when selected, liquid glass when not.
    @ViewBuilder
    func chipSurface(isSelected: Bool) -> some View {
        if isSelected {
            self.background(Color.lime, in: .capsule)
        } else {
            self.glassPanel(in: .capsule)
        }
    }
}

extension UIImage {
    /// Down-scales the image so profile photos stay small on disk.
    func downscaledJPEGData(maxDimension: CGFloat, quality: CGFloat = 0.8) -> Data? {
        let maxSide = max(size.width, size.height)
        let scale = min(1, maxDimension / maxSide)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let scaled = renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        return scaled.jpegData(compressionQuality: quality)
    }
}
