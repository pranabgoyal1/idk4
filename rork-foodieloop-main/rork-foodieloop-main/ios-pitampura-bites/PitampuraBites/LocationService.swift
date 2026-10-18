//
//  LocationService.swift
//  PitampuraBites
//
//  One-shot when-in-use location + reverse geocode so the Home header shows
//  the user's real area. Falls back to a manual area picker when permission
//  is denied or no fix arrives (e.g. the sandboxed cloud preview, which has
//  no location backend).
//

import CoreLocation
import os

@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    enum Status {
        /// Waiting for a GPS fix (short window after launch).
        case locating
        /// A fix resolved (GPS or manual pick).
        case resolved
        /// No fix available — the UI offers a manual area picker.
        case unavailable
    }

    private let log = Logger(subsystem: "app.pitampurabites", category: "location")
    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var fixTimeout: Task<Void, Never>?

    /// Resolved locality from reverse geocoding (or a manual pick), e.g. "Pitampura".
    private(set) var locality: String?
    /// Latest live fix (GPS or manual-area coordinate). Drives distances
    /// on the scan screen; nil when nothing has resolved yet.
    private(set) var currentLocation: CLLocation?
    private(set) var status: Status = .locating

    /// Name the UI shows; falls back to the home neighbourhood.
    var displayLocation: String {
        locality ?? "Pitampura, Delhi"
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Requests permission (first launch), then streams fixes until one
    /// resolves a locality or the short timeout offers the manual picker.
    func requestCurrentLocality() {
        log.info("requestCurrentLocality status=\(self.manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startFixing()
        case .denied, .restricted:
            status = .unavailable
        default:
            break
        }
    }

    /// Manual pick from the area sheet — always wins over GPS. Anchors
    /// distances to the locality's coordinate so they stay meaningful.
    func setManualLocality(_ name: String) {
        finishFixing()
        locality = name
        status = .resolved
        if let coords = MockData.localityCoordinates[name] {
            currentLocation = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
        }
        log.info("manual locality set: \(name, privacy: .public)")
    }

    /// Straight-line distance to a coordinate, or nil without a fix.
    func distanceMeters(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance? {
        currentLocation?.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }

    /// Shared "450 m" / "1.2 km" formatting.
    static func formatDistance(_ meters: CLLocationDistance) -> String {
        if meters < 1000 {
            return "\(Int(meters.rounded())) m"
        }
        return String(format: "%.1f km", meters / 1000)
    }

    // MARK: - Fix lifecycle

    private func startFixing() {
        guard status == .locating else { return }
        manager.startUpdatingLocation()

        // The first fix can stall indefinitely (no location backend in the
        // sandboxed preview) — offer the manual picker after a short wait.
        fixTimeout = Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            guard let self, self.currentLocation == nil else { return }
            self.finishFixing()
            self.status = .unavailable
            self.log.info("no GPS fix within timeout — offering manual area picker")
        }
    }

    private func finishFixing() {
        manager.stopUpdatingLocation()
        fixTimeout?.cancel()
        fixTimeout = nil
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        log.info("authorizationDidChange status=\(manager.authorizationStatus.rawValue)")
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startFixing()
        case .denied, .restricted:
            finishFixing()
            status = .unavailable
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        log.info("didUpdateLocations count=\(locations.count)")
        guard let location = locations.last else { return }
        // Keep streaming fixes so scanner distances stay live; only the
        // reverse geocode runs once.
        currentLocation = location
        status = .resolved
        guard locality == nil else { return }
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            let placemark = placemarks?.first
            let name = placemark.flatMap { $0.locality ?? $0.subLocality ?? $0.name }
            Task { @MainActor in
                if let name {
                    self.locality = name
                }
                self.log.info("geocode resolved: \(name ?? "nil", privacy: .public)")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log.error("didFailWithError: \(error.localizedDescription, privacy: .public)")
        // Updating keeps running until a valid fix or the timeout.
    }
}
