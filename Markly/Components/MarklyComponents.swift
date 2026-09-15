//
//  MarklyComponents.swift
//  Markly
//
// THIS FILE SHOULD EVENTUALLY STOP BEING USED AS I AM MIGRATING TO DIFFERENT CUSTOM COMPONENTS THAT HAVE THEIR OWN FILES
//

import SwiftUI

// MARK: - Glass Text Field

struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .horizontal
    var borderColor: Color = LColors.glassBorder
    var borderLineWidth: CGFloat = 1

    var body: some View {
        TextField(placeholder, text: $text, axis: axis)
            .foregroundStyle(LColors.textPrimary)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                    .fill(LColors.raisedSurfaces)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: borderLineWidth)
            )
            .clipShape(RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous))
    }
}

// MARK: - Sheet Header

struct MarklySheetHeader: View {
    let title: String
    var onClose: (() -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Text(title)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(LColors.secondaryAccent)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let onClose {
                Button(action: onClose) {
                    Image("xmark")
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .foregroundStyle(LColors.primaryText)
                        .frame(width: 38, height: 38)
                        .background(LColors.raisedSurfaces, in: Circle())
                        .overlay(
                            Circle()
                                .strokeBorder(LColors.glassBorder, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Load More Button

struct LoadMoreButton: View {
    var title: String = "Load More"
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(LColors.background)
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
                .background(AnyShapeStyle(LColors.indicators))
                .clipShape(Capsule())
                .shadow(color: LColors.indicators.opacity(0.25), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Markly Button

struct LButton: View {
    let title: String
    var icon: String? = nil
    var style: LButtonStyle = .primary
    var action: () -> Void

    enum LButtonStyle {
        case primary, secondary, success, danger
    }

    private var bgColor: AnyShapeStyle {
        switch style {
        case .primary:
            return AnyShapeStyle(LColors.accent)
        case .secondary:
            return AnyShapeStyle(LColors.secondaryAccent.opacity(0.22))
        case .success:
            return AnyShapeStyle(LColors.success)
        case .danger:
            return AnyShapeStyle(LColors.danger)
        }
    }

    private var fgColor: Color {
        switch style {
        case .secondary:
            return LColors.secondaryAccent
        case .success:
            return LColors.background
        case .danger:
            return LColors.textPrimary
        case .primary:
            return LColors.background
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(icon)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                }

                Text(title)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .foregroundStyle(fgColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                bgColor,
                in: RoundedRectangle(cornerRadius: LSpacing.buttonRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: LSpacing.buttonRadius)
                    .stroke(
                        buttonBorderColor,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var buttonBorderColor: Color {
        switch style {
        case .primary:
            return LColors.indicators.opacity(0.55)
        case .secondary:
            return LColors.secondaryAccent.opacity(0.78)
        case .success:
            return LColors.primaryActions.opacity(0.42)
        case .danger:
            return LColors.secondaryAccent.opacity(0.82)
        }
    }
}

// MARK: - DELETE CONFIRMATION DIALOGUE

struct MarklyAlertConfirm: ViewModifier {
    @Binding var isPresented: Bool

    let title: String
    let message: String
    let confirmTitle: String
    let confirmRole: ButtonRole?
    let onConfirm: () -> Void

    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button(confirmTitle, role: confirmRole) {
                    onConfirm()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(message)
            }
    }
}

extension View {
    func marklyAlertConfirm(
        isPresented: Binding<Bool>,
        title: String,
        message: String,
        confirmTitle: String = "Delete",
        confirmRole: ButtonRole? = .destructive,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.modifier(
            MarklyAlertConfirm(
                isPresented: isPresented,
                title: title,
                message: message,
                confirmTitle: confirmTitle,
                confirmRole: confirmRole,
                onConfirm: onConfirm
            )
        )
    }
}

// MARK: - Markly Popup (Reusable)

struct MarklyPopup<Header: View, Content: View, Footer: View>: View {
    let onClose: () -> Void
    let width: CGFloat
    let heightRatio: CGFloat

    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content
    @ViewBuilder let footer: () -> Footer

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.opacity(0.62)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            onClose()
                        }
                    }

                VStack(alignment: .leading, spacing: 18) {
                    header()

                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 14) {
                            content()
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .scrollBounceBehavior(.basedOnSize)

                    footer()
                }
                .padding(LSpacing.cardPadding)
                .frame(
                    width: max(
                        0,
                        min(
                            proxy.size.width.isFinite ? proxy.size.width - 40 : width,
                            width
                        )
                    ),
                    alignment: .topLeading
                )
                .frame(
                    maxHeight: proxy.size.height * heightRatio,
                    alignment: .topLeading
                )
                .background {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(LColors.bgSoft)
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(LColors.raisedSurfaces.opacity(0.72))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .strokeBorder(LColors.glassBorderStrong, lineWidth: 1.05)
                        }
                }
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color.black.opacity(0.22), radius: 16, y: 8)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

// MARK: - Markly Background

struct MarklyBackground: View {
    var body: some View {
        LColors.bg
            .ignoresSafeArea()
    }
}

// MARK: - Accent Time Drum Picker

struct MarklyAccentTimeDrumPicker: View {
    @Binding var hour: Int
    @Binding var minute: Int

    @State private var displayHour: Int = 9
    @State private var meridiem: String = "AM"
    @State private var isSyncingFromStoredHour = false

    private let meridiems = ["AM", "PM"]

    private var formattedPreview: String {
        String(format: "%d:%02d %@", displayHour, minute, meridiem)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image("clockfill")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 13, height: 13)
                    .foregroundStyle(LColors.secondaryAccent)

                Text(formattedPreview)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(LColors.glassSurface2, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(LColors.glassBorderStrong, lineWidth: 1)
            )

            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(LColors.glassSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(LColors.raisedSurfaces.opacity(0.56))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(LColors.glassBorderStrong, lineWidth: 1)
                    )

                VStack(spacing: 0) {
                    Spacer()
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LColors.indicators.opacity(0.20))
                        .frame(height: 38)
                    Spacer()
                }
                .padding(.horizontal, 12)

                HStack(spacing: 6) {
                    Picker("Hour", selection: $displayHour) {
                        ForEach(1...12, id: \.self) { value in
                            Text("\(value)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()

                    Text(":")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.secondaryAccent)

                    Picker("Minute", selection: $minute) {
                        ForEach(0..<60, id: \.self) { value in
                            Text(String(format: "%02d", value))
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()

                    Picker("AM PM", selection: $meridiem) {
                        ForEach(meridiems, id: \.self) { value in
                            Text(value)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .tag(value)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .clipped()
                }
                .padding(.horizontal, 8)
            }
            .frame(height: 138)
        }
        .onAppear { syncDisplayValuesFromStoredHour() }
        .onChange(of: displayHour) { syncStoredHour() }
        .onChange(of: meridiem) { syncStoredHour() }
        .onChange(of: hour) { syncDisplayValuesFromStoredHour() }
    }

    private func syncDisplayValuesFromStoredHour() {
        isSyncingFromStoredHour = true
        let normalizedHour = max(0, min(23, hour))

        if normalizedHour == 0 {
            displayHour = 12
            meridiem = "AM"
        } else if normalizedHour < 12 {
            displayHour = normalizedHour
            meridiem = "AM"
        } else if normalizedHour == 12 {
            displayHour = 12
            meridiem = "PM"
        } else {
            displayHour = normalizedHour - 12
            meridiem = "PM"
        }

        isSyncingFromStoredHour = false
    }

    private func syncStoredHour() {
        guard !isSyncingFromStoredHour else { return }

        if meridiem == "AM" {
            hour = displayHour == 12 ? 0 : displayHour
        } else {
            hour = displayHour == 12 ? 12 : displayHour + 12
        }
    }
}

// MARK: - Glass TextEditor

struct GlassTextEditor: View {
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 100
    var borderColor: Color = LColors.glassBorder
    var borderLineWidth: CGFloat = 1

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text(placeholder)
                    .foregroundStyle(LColors.textSecondary.opacity(0.65))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }

        TextEditor(text: $text)
                .foregroundStyle(LColors.textPrimary)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .frame(minHeight: minHeight)
        .background(
            RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                .fill(LColors.raisedSurfaces)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous)
                .strokeBorder(borderColor, lineWidth: borderLineWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: LSpacing.inputRadius, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        MarklyBackground()

        GlassCard {
            VStack(spacing: 10) {
                Text("Markly")
                    .font(.system(size: 42, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.secondaryAccent)

                Text("Glass card preview")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
        }
        .padding(.horizontal, 24)
    }
}
