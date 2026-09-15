//
//  CustomSheet.swift
//  Markly
//
//  Device-adaptive presentation surface. iPhone uses `.sheet`; iPad
//  uses `.fullScreenCover`. Custom header with a custom exit button —
//  no system toolbar items.
//

import SwiftUI

// MARK: - Modifier

private struct CustomSheetPresenter<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var title: String
    var onDismiss: (() -> Void)?
    @ViewBuilder var sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        if isPad {
            content.fullScreenCover(isPresented: $isPresented, onDismiss: onDismiss) {
                CustomSheetChrome(title: title, isPresented: $isPresented) {
                    sheetContent()
                }
            }
        } else {
            content.sheet(isPresented: $isPresented, onDismiss: onDismiss) {
                CustomSheetChrome(title: title, isPresented: $isPresented) {
                    sheetContent()
                }
            }
        }
    }
}

private struct AdaptiveSheetPresenter<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    var onDismiss: (() -> Void)?
    @ViewBuilder var sheetContent: () -> SheetContent

    func body(content: Content) -> some View {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        if isPad {
            content.fullScreenCover(isPresented: $isPresented, onDismiss: onDismiss) {
                sheetContent()
            }
        } else {
            content.sheet(isPresented: $isPresented, onDismiss: onDismiss) {
                sheetContent()
            }
        }
    }
}

private struct AdaptiveItemSheetPresenter<Item: Identifiable, SheetContent: View>: ViewModifier {
    @Binding var item: Item?
    var onDismiss: (() -> Void)?
    @ViewBuilder var sheetContent: (Item) -> SheetContent

    func body(content: Content) -> some View {
        let isPad = UIDevice.current.userInterfaceIdiom == .pad

        if isPad {
            content.fullScreenCover(item: $item, onDismiss: onDismiss) { item in
                sheetContent(item)
            }
        } else {
            content.sheet(item: $item, onDismiss: onDismiss) { item in
                sheetContent(item)
            }
        }
    }
}

extension View {
    func customSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        title: String,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(CustomSheetPresenter(
            isPresented: isPresented,
            title: title,
            onDismiss: onDismiss,
            sheetContent: content
        ))
    }

    func adaptiveSheet<SheetContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> SheetContent
    ) -> some View {
        modifier(AdaptiveSheetPresenter(
            isPresented: isPresented,
            onDismiss: onDismiss,
            sheetContent: content
        ))
    }

    func adaptiveSheet<Item: Identifiable, SheetContent: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> SheetContent
    ) -> some View {
        modifier(AdaptiveItemSheetPresenter(
            item: item,
            onDismiss: onDismiss,
            sheetContent: content
        ))
    }
}

// MARK: - Chrome

struct CustomSheetChrome<Content: View>: View {
    @Environment(\.appTheme) private var theme
    var title: String
    @Binding var isPresented: Bool
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            AppBackground()

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Text(title)
                        .font(theme.typography.pageTitle)
                        .foregroundStyle(theme.palette.textPrimary)
                    Spacer(minLength: 0)
                    CustomIconButton(asset: "exitdoor", size: 18) {
                        isPresented = false
                    }
                }
                .padding(.horizontal, theme.metrics.pageHPadding)
                .padding(.top, theme.metrics.spacingL)
                .padding(.bottom, theme.metrics.spacingS)

                content()
            }
        }
    }
}
