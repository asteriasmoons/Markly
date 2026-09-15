//
//  SignOutView.swift
//  Markly
//

import SwiftUI

struct SignOutView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image("xmark")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(LColors.secondaryAccent)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.bottom, 10)

                GlassCard {
                    VStack(spacing: 16) {
                        VStack(spacing: 6) {
                            Text("Sign Out")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.secondaryAccent)

                            Text("You’ll stay safely signed out on this device until you sign in again with Apple.")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(LColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Button {
                            appState.signOut()
                            dismiss()
                        } label: {
                            Text("Sign Out")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background {
                                    BubblyTileSurface(tint: LColors.primaryActions, cornerRadius: LSpacing.buttonRadius)
                                }
                                .bubblyTileLift()
                        }
                        .buttonStyle(.plain)

                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .font(.system(size: 15, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background {
                                    BubblyTileSurface(tint: LColors.secondaryAccent, cornerRadius: LSpacing.buttonRadius)
                                }
                                .bubblyTileLift()
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(LColors.indicators, lineWidth: 1.2)
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 22)
            .frame(maxWidth: 520)
        }
        .presentationDetents([.height(350)])
        .presentationDragIndicator(.visible)
    }
}
