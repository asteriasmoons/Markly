//
//  MarklyReportFormComponents.swift
//  Markly
//

import PhotosUI
import SwiftUI
import UIKit

enum MarklyReportFormOptions {
    static let areas = [
        "General",
        "Library",
        "Bookmarks",
        "Bookmark Detail",
        "Bookmark Editor",
        "Bookmark Preview",
        "Bookmark Notes",
        "Move Bookmark",
        "Folders",
        "Folder Detail",
        "Tags",
        "Search",
        "Favorites",
        "Archive",
        "Pinned Items",
        "Pins",
        "Collections",
        "Pin Collections",
        "Pin Collection Editor",
        "Reader",
        "Reader Extraction",
        "Reader Text",
        "Reader Settings",
        "Reader Toolbar",
        "Original View",
        "Notes",
        "Activity",
        "Activity Filters",
        "Activity Stats",
        "Settings",
        "Account",
        "Sign In",
        "Sign Out",
        "Cloud Sync",
        "Import Bookmarks",
        "Import Status",
        "Destination Folder",
        "Export Bookmarks",
        "Shared Folders",
        "Share Extension",
        "Tab Bar",
        "Icons",
        "Theme",
        "Notifications",
        "Widgets",
        "Support",
        "Submitted Reports",
        "Privacy Policy",
        "Terms of Service"
    ]
}

struct MarklyReportFormScaffold<Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    var eyebrow: String? = nil
    let title: String
    var titleColor: Color = LColors.primaryText
    var closeColor: Color = LColors.primaryText
    var closeIsIconOnly: Bool = false
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
                    MarklyReportHeader(
                        eyebrow: eyebrow,
                        title: title,
                        titleColor: titleColor,
                        closeColor: closeColor,
                        closeIsIconOnly: closeIsIconOnly
                    ) {
                        dismiss()
                    }
                    content()
                }
                .padding(.horizontal, LSpacing.pageHorizontal)
                .padding(.top, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .marklyDismissKeyboardOnOutsideTap()
    }
}

struct MarklyReportHeader: View {
    let eyebrow: String?
    let title: String
    var titleColor: Color = LColors.primaryText
    var closeColor: Color = LColors.primaryText
    var closeIsIconOnly: Bool = false
    let onClose: () -> Void

    var body: some View {
        if closeIsIconOnly && (eyebrow?.isEmpty ?? true) {
            HStack(alignment: .center) {
                titleText

                Spacer()

                closeButton
            }
        } else {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    eyebrowText
                    titleText
                }

                Spacer()

                closeButton
                    .padding(.top, 16)
            }
        }
    }

    @ViewBuilder
    private var eyebrowText: some View {
        if let eyebrow, !eyebrow.isEmpty {
            Text(eyebrow.uppercased())
                .font(.system(size: 13, weight: .black, design: .rounded))
                .tracking(3)
                .foregroundStyle(LColors.indicators)
        }
    }

    private var titleText: some View {
        Text(title)
            .font(.system(size: 30, weight: .black, design: .rounded))
            .foregroundStyle(titleColor)
    }

    private var closeButton: some View {
        Button(action: onClose) {
            CustomAssetIcon(name: "xmark", size: closeIsIconOnly ? 30 : 17, tint: closeColor)
                .frame(width: closeIsIconOnly ? 30 : 44, height: closeIsIconOnly ? 30 : 44)
                .background {
                    if !closeIsIconOnly {
                        Circle()
                            .fill(LColors.raisedSurfaces)
                    }
                }
                .overlay {
                    if !closeIsIconOnly {
                        Circle()
                            .strokeBorder(LColors.indicators, lineWidth: 1)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }

struct MarklyReportIntroCard: View {
    let title: String
    let message: String
    var borderColor: Color? = nil
    var titleColor: Color = LColors.primaryText

    var body: some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 17, weight: .black, design: .rounded))
                    .foregroundStyle(titleColor)

                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay {
            if let borderColor {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1.2)
            }
        }
    }
}

struct MarklyReportSectionHeader: View {
    let title: String
    var color: Color = LColors.primaryText

    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundStyle(color)
    }
}

struct MarklyReportTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var accent: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabelView(text: title, color: accent ?? LColors.textSecondary)
            GlassTextField(
                placeholder: placeholder,
                text: $text,
                borderColor: accent ?? LColors.raisedSurfaces,
                borderLineWidth: accent == nil ? 0.5 : 1.2
            )
        }
    }
}

struct MarklyReportTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 130
    var accent: Color? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            FieldLabelView(text: title, color: accent ?? LColors.textSecondary)
            GlassTextEditor(
                placeholder: placeholder,
                text: $text,
                minHeight: minHeight,
                borderColor: accent ?? LColors.raisedSurfaces,
                borderLineWidth: accent == nil ? 0.5 : 1.2
            )
        }
    }
}

struct MarklyReportPickerField: View {
    let title: String
    let options: [String]
    @Binding var selection: String
    var accent: Color? = nil

    private var dropdownOptions: [MarklyReportDropdownOption] {
        options.map { MarklyReportDropdownOption(value: $0) }
    }

    private var selectedOption: Binding<MarklyReportDropdownOption?> {
        Binding(
            get: {
                dropdownOptions.first { $0.value == selection }
            },
            set: { option in
                if let option {
                    selection = option.value
                }
            }
        )
    }

    var body: some View {
        CustomDropdown(
            title: title,
            options: dropdownOptions,
            labelFor: { $0.value },
            accent: accent,
            maxVisibleRows: 4,
            showsDividers: false,
            selection: selectedOption
        )
    }
}

private struct MarklyReportDropdownOption: Identifiable, Hashable {
    let value: String

    var id: String { value }
}

struct MarklyReportDynamicStepsField: View {
    let title: String
    @Binding var steps: [String]
    var maxSteps: Int = 10
    var accent: Color? = nil

    var body: some View {
        let activeAccent = accent ?? LColors.raisedSurfaces

        VStack(alignment: .leading, spacing: 8) {
            FieldLabelView(text: title, color: accent ?? LColors.textSecondary)

            VStack(spacing: 10) {
                ForEach(steps.indices, id: \.self) { index in
                    GlassTextField(
                        placeholder: "Step \(index + 1)...",
                        text: $steps[index],
                        axis: .vertical,
                        borderColor: activeAccent,
                        borderLineWidth: accent == nil ? 0.5 : 1.2
                    )
                }
            }

            if steps.count < maxSteps {
                Button {
                    steps.append("")
                } label: {
                    CustomAssetIcon(name: "addwavy", size: 18, tint: LColors.primaryText)
                        .frame(width: 44, height: 44)
                        .background {
                            if let accent {
                                BubblyTileSurface(tint: accent, cornerRadius: 14)
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(LColors.raisedSurfaces)
                            }
                        }
                        .bubblyTileLift(isEnabled: accent != nil)
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            if steps.isEmpty { steps = [""] }
            if steps.count > maxSteps { steps = Array(steps.prefix(maxSteps)) }
        }
    }
}

struct MarklyReportAttachmentsPicker: View {
    let title: String
    @Binding var selectedPhotos: [PhotosPickerItem]
    let attachmentCount: Int
    var accent: Color? = nil

    var body: some View {
        let activeAccent = accent ?? LColors.primaryText

        VStack(alignment: .leading, spacing: 12) {
            MarklyReportSectionHeader(title: title, color: activeAccent)

            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 3, matching: .images) {
                HStack(spacing: 14) {
                    CustomAssetIcon(name: "image", size: 22, tint: LColors.primaryText)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Add Screenshots")
                            .font(.system(size: 15, weight: .black, design: .rounded))
                            .foregroundStyle(LColors.primaryText)

                        Text("Up to 3 images")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(LColors.textSecondary)
                    }

                    Spacer()

                    Text("\(attachmentCount)/3")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.primaryText)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background {
                    if let accent {
                        BubblyTileSurface(tint: accent, cornerRadius: 18)
                    } else {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LColors.surfaces)
                    }
                }
                .bubblyTileLift(isEnabled: accent != nil)
            }
            .buttonStyle(.plain)
        }
    }
}

struct MarklyReportDiagnosticsCard: View {
    let message: String
    var borderColor: Color? = nil
    var titleColor: Color = LColors.primaryText

    var body: some View {
        GlassCard(cornerRadius: 22) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Automatic Diagnostics")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(titleColor)

                Text(message)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .overlay {
            if let borderColor {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(borderColor, lineWidth: 1.2)
            }
        }
    }
}

struct MarklyReportErrorCard: View {
    let message: String

    var body: some View {
        GlassCard(cornerRadius: 18) {
            Text(message)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(LColors.danger)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct MarklyReportSuccessCard: View {
    let title: String
    let reportID: String

    var body: some View {
        GlassCard(cornerRadius: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.success)

                Text("Voxiverse report ID: \(reportID)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
            }
        }
    }
}

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

extension View {
    func marklyDismissKeyboardOnOutsideTap() -> some View {
        background {
            MarklyKeyboardDismissBridge()
                .frame(width: 0, height: 0)
        }
    }
}

private struct MarklyKeyboardDismissBridge: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> AttachmentView {
        let view = AttachmentView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: AttachmentView, context: Context) {
        uiView.coordinator = context.coordinator
        context.coordinator.attach(to: uiView.window)
    }

    static func dismantleUIView(_ uiView: AttachmentView, coordinator: Coordinator) {
        coordinator.detach()
    }

    final class AttachmentView: UIView {
        weak var coordinator: Coordinator?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            coordinator?.attach(to: window)
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var attachedWindow: UIWindow?
        private var recognizer: UITapGestureRecognizer?

        func attach(to window: UIWindow?) {
            guard let window else {
                detach()
                return
            }
            guard attachedWindow !== window else { return }

            detach()

            let recognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            window.addGestureRecognizer(recognizer)

            attachedWindow = window
            self.recognizer = recognizer
        }

        func detach() {
            if let recognizer {
                attachedWindow?.removeGestureRecognizer(recognizer)
            }
            recognizer = nil
            attachedWindow = nil
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var touchedView: UIView? = touch.view

            while let view = touchedView {
                if view is UITextField || view is UITextView || view is UIControl {
                    return false
                }
                touchedView = view.superview
            }

            return true
        }

        @objc private func dismissKeyboard() {
            attachedWindow?.endEditing(true)
        }
    }
}
