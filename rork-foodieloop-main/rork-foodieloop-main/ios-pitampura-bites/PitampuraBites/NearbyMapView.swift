//
//  NearbyMapView.swift
//  PitampuraBites
//
//  In-app map (opened from the scanner's "locate on maps") showing every
//  onboarded outlet as a lime pin plus the user's position. Tapping a pin
//  opens a card with the outlet's live distance and a button into its page.
//

import SwiftUI
import MapKit

struct NearbyMapView: View {
    /// User's resolved position; the map centres on Pitampura as a fallback.
    let userCoordinate: CLLocationCoordinate2D?
    /// Shared service so the card's distance stays live.
    let locationService: LocationService

    @Environment(\.dismiss) private var dismiss
    @State private var selectedShop: Shop?
    @State private var detailShop: Shop?

    private var centerCoordinate: CLLocationCoordinate2D {
        userCoordinate ?? CLLocationCoordinate2D(latitude: 28.6966, longitude: 77.1510)
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                map
                if let selectedShop {
                    shopCard(selectedShop)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.spring(duration: 0.4), value: selectedShop)
            .navigationTitle("Onboarded outlets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.lime)
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(item: $detailShop) { shop in
            ShopDetailView(shop: shop)
        }
    }

    private var map: some View {
        Map(initialPosition: .camera(MapCamera(centerCoordinate: centerCoordinate, distance: 3200))) {
            if let userCoordinate {
                Annotation("You are here", coordinate: userCoordinate) {
                    userDot
                }
                .annotationTitles(.hidden)
            }
            ForEach(MockData.shops) { shop in
                Annotation(shop.name, coordinate: shop.coordinate) {
                    Button {
                        UISelectionFeedbackGenerator().selectionChanged()
                        withAnimation(.spring(duration: 0.35)) { selectedShop = shop }
                    } label: {
                        pin(isSelected: selectedShop?.id == shop.id)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(shop.name), \(shop.subtitle)")
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
    }

    private var userDot: some View {
        ZStack {
            Circle()
                .fill(Color.lime.opacity(0.25))
                .frame(width: 36, height: 36)
            Circle()
                .fill(Color.lime)
                .frame(width: 14, height: 14)
                .overlay(Circle().strokeBorder(.white, lineWidth: 2))
        }
        .accessibilityLabel("Your location")
    }

    private func pin(isSelected: Bool) -> some View {
        Image(systemName: "storefront.fill")
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(.black)
            .frame(width: isSelected ? 42 : 32, height: isSelected ? 42 : 32)
            .background(Color.lime, in: .circle)
            .overlay(Circle().strokeBorder(.white, lineWidth: isSelected ? 2.5 : 1.5))
            .shadow(radius: 3)
            .animation(.spring(duration: 0.3), value: isSelected)
    }

    @ViewBuilder
    private func shopCard(_ shop: Shop) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                Image(shop.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(.rect(cornerRadius: 16))
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 4) {
                    Text(shop.name)
                        .font(.system(size: 19, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    HStack(spacing: 10) {
                        RatingBadge(rating: shop.rating, fontSize: 13)
                        Text(shop.subtitle)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appTextSecondary)
                            .lineLimit(1)
                    }
                    if let distance = locationService.distanceMeters(to: shop.coordinate) {
                        Text(LocationService.formatDistance(distance))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.lime)
                    }
                }
            }

            PrimaryButton(title: "View place") {
                detailShop = shop
            }
        }
        .padding(18)
        .background(Color.appSurface, in: .rect(cornerRadius: 24))
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }
}
