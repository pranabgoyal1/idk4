//
//  OnboardingFlow.swift
//  PitampuraBites
//
//  Simulated sign-up: phone entry, OTP, display name, username, avatar.
//  Clearly labelled as a demo — no SMS is sent and nothing leaves the device.
//

import SwiftUI
import PhotosUI

struct OnboardingFlow: View {
    @Environment(AppState.self) private var appState

    private enum Step: Int, CaseIterable {
        case phone, otp, displayName, username, avatar
    }

    @State private var step: Step = .phone
    @State private var phone = ""
    @State private var otp = ""
    @State private var name = ""
    @State private var username = ""
    @State private var avatarImageData: Data?

    var body: some View {
        VStack(spacing: 0) {
            ProgressBar(stepIndex: step.rawValue, stepCount: Step.allCases.count)
                .padding(.horizontal, .screenMargin)
                .padding(.top, 8)

            Group {
                switch step {
                case .phone: PhoneStep(phone: $phone, onNext: advance)
                case .otp: OTPStep(phone: phone, otp: $otp, onNext: advance)
                case .displayName: NameStep(name: $name, onNext: advance)
                case .username: UsernameStep(name: name, username: $username, onNext: advance)
                case .avatar: AvatarStep(name: name, imageData: $avatarImageData, onDone: complete)
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
        }
        .animation(.spring(duration: 0.4), value: step)
        .background(Color.appBackground)
        .task { appState.location.requestCurrentLocality() }
    }

    private func advance() {
        withAnimation { step = Step(rawValue: step.rawValue + 1) ?? .avatar }
    }

    private func complete() {
        appState.displayName = name.isEmpty ? "Explorer" : name
        appState.username = username
        appState.avatarImageData = avatarImageData
        appState.hasOnboarded = true
    }
}

/// Thin segmented lime progress bar at the top of onboarding.
private struct ProgressBar: View {
    let stepIndex: Int
    let stepCount: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<stepCount, id: \.self) { index in
                Capsule()
                    .fill(index <= stepIndex ? Color.lime : Color.appSurfaceRaised)
                    .frame(height: 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Small step heading + subline used by all steps.
private struct StepHeading: View {
    let title: String
    let subline: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(.white)
            Text(subline)
                .font(.system(size: 15))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Demo disclosure shown on the phone step — authentication is a placeholder.
private struct DemoBadge: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
            Text("Demo sign-up — no SMS is sent")
        }
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(Color.appTextSecondary)
    }
}

private struct PhoneStep: View {
    @Binding var phone: String
    let onNext: () -> Void

    private var isValid: Bool {
        phone.filter(\.isNumber).count == 10
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Spacer(minLength: 24)

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.lime)
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.black)
                    }
                Text("Pitampura Bites")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
            }

            StepHeading(
                title: "What's your number?",
                subline: "We'll text you a code. Well — in the real app we would."
            )

            HStack(spacing: 12) {
                Text("+91")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                TextField("98765 43210", text: $phone)
                    .keyboardType(.numberPad)
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
                    .onChange(of: phone) { _, newValue in
                        phone = String(newValue.filter(\.isNumber).prefix(10))
                    }
            }
            .padding(.horizontal, 18)
            .frame(height: 54)
            .glassPanel(in: .rect(cornerRadius: 18))

            DemoBadge()

            Spacer()

            PrimaryButton(title: "Continue", isEnabled: isValid, action: onNext)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, .screenMargin)
    }
}

private struct OTPStep: View {
    let phone: String
    @Binding var otp: String
    let onNext: () -> Void

    @FocusState private var isFocused: Bool

    private var isValid: Bool { otp.count == 4 }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Spacer(minLength: 24)

            StepHeading(
                title: "Enter the code",
                subline: "Sent to +91 \(phone). Demo tip: any 4 digits work."
            )

            TextField("••••", text: $otp)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .multilineTextAlignment(.center)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(height: 64)
                .glassPanel(in: .rect(cornerRadius: 18))
                .onChange(of: otp) { _, newValue in
                    otp = String(newValue.filter(\.isNumber).prefix(4))
                    if otp.count == 4 { onNext() }
                }
                .onAppear { isFocused = true }

            DemoBadge()

            Spacer()

            PrimaryButton(title: "Verify", isEnabled: isValid, action: onNext)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, .screenMargin)
    }
}

private struct NameStep: View {
    @Binding var name: String
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Spacer(minLength: 24)

            StepHeading(title: "Your name", subline: "What should friends see when you review a place?")

            TextField("Your full name", text: $name)
                .font(.system(size: 17))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .frame(height: 54)
                .glassPanel(in: .rect(cornerRadius: 18))
                .submitLabel(.done)
                .onSubmit(onNext)

            Spacer()

            PrimaryButton(title: "Continue", isEnabled: !name.trimmingCharacters(in: .whitespaces).isEmpty, action: onNext)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, .screenMargin)
    }
}

private struct UsernameStep: View {
    /// The display name entered on the previous step, used for suggestions.
    let name: String
    @Binding var username: String
    let onNext: () -> Void

    private var cleaned: String {
        username.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    /// Placeholder derived from the typed name, never a hardcoded one.
    private var placeholder: String {
        let first = name.lowercased().split(separator: " ").first.map(String.init) ?? ""
        return first.isEmpty ? "yourhandle" : first
    }

    private var isTaken: Bool { MockData.takenUsernames.contains(cleaned) }
    private var isValid: Bool { cleaned.count >= 3 && !isTaken }

    private var hint: (text: String, color: Color)? {
        if cleaned.count < 3 { return nil }
        if isTaken { return ("@\(cleaned) is taken — try another.", Color.hotPink) }
        return ("@\(cleaned) is available ✓", Color.lime)
    }

    /// Up to six handle suggestions built from the user's display name.
    private var suggestions: [String] {
        let parts = name.lowercased()
            .split(separator: " ")
            .map { String($0).filter { $0.isLetter || $0.isNumber } }
            .filter { !$0.isEmpty }
        guard let first = parts.first else { return [] }

        let suffixes = ["", ".eats", "_eats", ".bites", "_bites", ".foodie"]
        let raw: [String]
        if parts.count > 1, let last = parts.last, last != first {
            raw = [
                "\(first)-\(last)",
                "\(first).\(last)",
                "\(first)_\(last)",
                "\(first)\(last)",
                "\(last)-\(first)",
                "\(first)-\(last)-eats"
            ]
        } else {
            raw = suffixes.map { "\(first)\($0)" }
        }

        var taken: Set<String> = [cleaned]
        var unique: [String] = []
        for candidate in raw
        where candidate.count >= 3
            && !MockData.takenUsernames.contains(candidate)
            && !taken.contains(candidate) {
            taken.insert(candidate)
            unique.append(candidate)
            if unique.count == 6 { break }
        }
        return unique
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Spacer(minLength: 24)

            StepHeading(title: "Pick a handle", subline: "Your reviews show up under this name in the Circle.")

            HStack(spacing: 2) {
                Text("@")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary)
                TextField(placeholder, text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.system(size: 17))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 18)
            .frame(height: 54)
            .glassPanel(in: .rect(cornerRadius: 18))

            if let hint {
                Text(hint.text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(hint.color)
            }

            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggestions for you")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.appTextSecondary)
                        .textCase(.uppercase)
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            ForEach(suggestions, id: \.self) { suggestion in
                                Button {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    withAnimation(.spring(duration: 0.3)) { username = suggestion }
                                } label: {
                                    Text("@\(suggestion)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(username == suggestion ? .black : .white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .background(username == suggestion ? Color.lime : Color.appSurface, in: .capsule)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Use handle \(suggestion)")
                            }
                        }
                        .padding(.horizontal, .screenMargin)
                    }
                    .scrollIndicators(.hidden)
                    .contentMargins(.horizontal, -.screenMargin, for: .scrollContent)
                }
            }

            Spacer()

            PrimaryButton(title: "Continue", isEnabled: isValid, action: onNext)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, .screenMargin)
    }
}

private struct AvatarStep: View {
    let name: String
    @Binding var imageData: Data?
    let onDone: () -> Void

    @Environment(AppState.self) private var appState
    @State private var photoItem: PhotosPickerItem?
    @State private var showAreaPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Spacer(minLength: 24)

            StepHeading(title: "Add a photo?", subline: "Optional — you'll get a clean default avatar without one.")

            AvatarView(imageData: imageData, size: 120, showsRing: true)
                .frame(maxWidth: .infinity)

            HStack(spacing: 12) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.badge.plus")
                            .font(.system(size: 15, weight: .semibold))
                        Text(imageData == nil ? "Upload photo" : "Change photo")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .frame(height: 48)
                    .glassPanel(in: .capsule)
                }
                .buttonStyle(.plain)

                if imageData != nil {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        withAnimation(.spring(duration: 0.3)) { imageData = nil }
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

            profilePreview

            Spacer()

            PrimaryButton(title: "Start exploring", systemImage: "flame", action: onDone)
                .padding(.bottom, 24)
        }
        .padding(.horizontal, .screenMargin)
        .sheet(isPresented: $showAreaPicker) {
            AreaPickerSheet(selected: appState.location.displayLocation) {
                appState.location.setManualLocality($0)
            }
            .presentationDetents([.medium])
            .presentationBackground(Color.appBackground)
        }
        .onChange(of: photoItem) { _, item in
            loadPhoto(from: item)
        }
    }

    /// Live profile preview. The location line is tappable when GPS can't
    /// resolve (sandboxed preview), so the area is never hardcoded.
    @ViewBuilder
    private var profilePreview: some View {
        let locationLine = HStack(spacing: 4) {
            Image(systemName: appState.location.status == .unavailable ? "location.slash" : "location.fill")
                .font(.system(size: 10))
            Text(appState.location.displayLocation)
                .font(.system(size: 13))
            if appState.location.status == .unavailable {
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .semibold))
            }
        }
        .foregroundStyle(Color.appTextSecondary)

        HStack(spacing: 12) {
            AvatarView(imageData: imageData, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(name.isEmpty ? "Explorer" : name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                locationLine
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassPanel(in: .rect(cornerRadius: 20))
        .contentShape(.rect)
        .modifier(AreaTapModifier(showPicker: appState.location.status == .unavailable) {
            showAreaPicker = true
        })
        .accessibilityElement(children: .combine)
        .accessibilityLabel(appState.location.status == .unavailable ? "Area \(appState.location.displayLocation). Tap to choose your area" : "Area \(appState.location.displayLocation)")
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task { @MainActor in
            let data = try? await item.loadTransferable(type: Data.self)
            guard let data, let image = UIImage(data: data) else { return }
            UISelectionFeedbackGenerator().selectionChanged()
            imageData = image.downscaledJPEGData(maxDimension: 640)
        }
    }
}
