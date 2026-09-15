//
//  SignInView.swift
//  Markly
//

import SwiftUI
import SwiftData
import AuthenticationServices

struct SignInView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @Query private var authUsers: [AuthUser]

    @State private var isSigningIn = false
    @State private var errorText: String?

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
                            Text("Sign In")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.secondaryAccent)

                            Text("Use Apple to sync your Markly data across devices.")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .multilineTextAlignment(.center)
                                .foregroundStyle(LColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let errorText {
                            Text(errorText)
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(LColors.danger)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.fullName, .email]
                        } onCompletion: { result in
                            handleAppleSignIn(result)
                        }
                        .signInWithAppleButtonStyle(.white)
                        .frame(height: 50)
                        .clipShape(RoundedRectangle(cornerRadius: LSpacing.buttonRadius, style: .continuous))
                        .disabled(isSigningIn)
                        .opacity(isSigningIn ? 0.65 : 1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 22)
            .frame(maxWidth: 520)
        }
        .presentationDetents([.height(330)])
        .presentationDragIndicator(.visible)
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        errorText = nil
        isSigningIn = true

        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                isSigningIn = false
                errorText = "Apple Sign In returned an unexpected credential."
                return
            }

            do {
                let signedInUser = try AuthService.shared.signInWithApple(
                    credential: credential,
                    existingUsers: authUsers,
                    modelContext: modelContext
                )

                try modelContext.save()
                appState.setSignedIn(signedInUser)
                isSigningIn = false
                dismiss()
            } catch {
                isSigningIn = false
                errorText = error.localizedDescription
            }

        case .failure(let error):
            isSigningIn = false
            if let authError = error as? ASAuthorizationError,
               authError.code == .canceled {
                return
            }
            errorText = error.localizedDescription
        }
    }
}
