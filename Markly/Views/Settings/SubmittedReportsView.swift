//
//  SubmittedReportsView.swift
//  Markly
//

import SwiftData
import SwiftUI

struct SubmittedReportsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \SubmittedReport.submittedAt, order: .reverse) private var reports: [SubmittedReport]
    @State private var selectedReport: SubmittedReport?

    private let reportGridColumns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    private let reportGridCardContentHeight: CGFloat = 144
    private let reportGridTitleHeight: CGFloat = 18

    var body: some View {
        ZStack {
            MarklyBackground()
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: LSpacing.sectionGap) {
                    submittedReportsHeader

                    if reports.isEmpty {
                        emptyState
                    } else {
                        LazyVGrid(columns: reportGridColumns, spacing: 12) {
                            ForEach(Array(reports.enumerated()), id: \.element.id) { index, report in
                                Button {
                                    selectedReport = report
                                } label: {
                                    submittedReportCard(report, accent: accent(for: index))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
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
        .adaptiveSheet(item: $selectedReport) { report in
            SubmittedReportDetailView(report: report)
        }
    }

    private var submittedReportsHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("REPORTS")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .tracking(3)
                .foregroundStyle(LColors.indicators)

            HStack(alignment: .center) {
                Text("Submitted Reports")
                    .font(.system(size: 30, weight: .black, design: .rounded))
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
        }
    }

    private var emptyState: some View {
        GlassCard(cornerRadius: 22) {
            VStack(spacing: 10) {
                CustomAssetIcon(name: "emptyinbox", size: 34, tint: LColors.indicators)

                Text("No submitted reports")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(LColors.primaryText)

                Text("Bug reports, beta feedback, and feature requests sent from this device will appear here.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(LColors.primaryActions, lineWidth: 1.2)
        }
    }

    private func submittedReportCard(_ report: SubmittedReport, accent: Color) -> some View {
        GlassCard(cornerRadius: 22, padding: 11) {
            VStack(alignment: .center, spacing: 8) {
                liquidGlassReportIcon(name: reportIconName(for: report), accent: accent)

                Text(report.title)
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .foregroundStyle(accent)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, minHeight: reportGridTitleHeight, maxHeight: reportGridTitleHeight)

                VStack(alignment: .center, spacing: 3) {
                    Text(report.submittedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .multilineTextAlignment(.center)

                    Text(report.reportType)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(LColors.textSecondary)
                        .multilineTextAlignment(.center)

                    Text(report.reportID)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(accent)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 12) {
                    if !report.attachments.isEmpty {
                        CustomAssetIcon(name: "image", size: 17, tint: accent)
                    }

                    CustomAssetIcon(name: "chevright", size: 15, tint: LColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, minHeight: reportGridCardContentHeight, maxHeight: reportGridCardContentHeight)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(accent, lineWidth: 1.2)
        }
    }

    @ViewBuilder
    private func liquidGlassReportIcon(name: String, accent: Color) -> some View {
        ZStack {
            BubblyTileSurface(tint: accent, cornerRadius: 18)
                .clipShape(Circle())
                .overlay {
                    Circle()
                        .strokeBorder(accent, lineWidth: 1.2)
                }

            CustomAssetIcon(name: name, size: 19, tint: LColors.primaryText)
        }
        .frame(width: 45, height: 45)
        .bubblyTileLift()
    }

    private func reportIconName(for report: SubmittedReport) -> String {
        switch report.reportType {
        case "Beta Feedback":
            return "chatlines"
        case "Feature Request":
            return "brightbulb"
        default:
            return "bug"
        }
    }

    private func accent(for index: Int) -> Color {
        switch index % 3 {
        case 1:
            return LColors.secondaryAccent
        case 2:
            return LColors.indicators
        default:
            return LColors.primaryActions
        }
    }
}
