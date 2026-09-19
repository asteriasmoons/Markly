//
//  SubmittedReportImageView.swift
//  Markly
//

import SwiftUI
import UIKit

struct SubmittedReportImageView: View {
    @Environment(\.dismiss) private var dismiss
    let attachment: SubmittedReportAttachment

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            VStack(spacing: 18) {
                HStack {
                    Text(attachment.displayName)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.secondaryAccent)

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        CustomAssetIcon(name: "xmark", size: 30, tint: LColors.secondaryAccent)
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }

                if let image = UIImage(data: attachment.imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                } else {
                    GlassCard(cornerRadius: 22) {
                        VStack(spacing: 10) {
                            CustomAssetIcon(name: "image", size: 34, tint: LColors.textSecondary)
                            Text("Image unavailable")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(LColors.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, LSpacing.pageHorizontal)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }
}
