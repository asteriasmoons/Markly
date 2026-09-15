//
//  CustomDrumPicker.swift
//  Markly
//
//  Matches the Lurelia reference drum picker: one raisedSurface pill
//  container, one center selection band with a subtle textSecondary
//  rounded border spanning every column, three rows visible total
//  (previous / selected / next), tight vertical rhythm, compact height,
//  no gradients, no opacity variants. Selected row uses textPrimary,
//  neighbors use textSecondary — visible dim through palette color
//  choice alone.
//

import SwiftUI

// MARK: - Bare wheel (a single scrollable column, no chrome)

struct CustomDrumWheel<Item: Hashable>: View {
    @Environment(\.appTheme) private var theme

    var items: [Item]
    var label: (Item) -> String
    @Binding var selection: Item

    /// Width of this wheel column.
    var width: CGFloat = 64
    /// Height of one row inside the wheel.
    var rowHeight: CGFloat = 40
    /// Total rows visible (should be an odd number: previous / selected / next…).
    var visibleRows: Int = 3
    var selectedFont: Font? = nil
    var neighborFont: Font? = nil

    @State private var dragOffset: CGFloat = 0
    @State private var baseOffset: CGFloat = 0
    @State private var isDragging = false

    private var selectedIndex: Int {
        items.firstIndex(of: selection) ?? 0
    }

    private var totalOffset: CGFloat {
        baseOffset + dragOffset
    }

    private var currentIndex: Int {
        guard !items.isEmpty else { return 0 }
        let raw = -totalOffset / rowHeight
        return max(0, min(items.count - 1, Int(raw.rounded())))
    }

    var body: some View {
        let height = rowHeight * CGFloat(visibleRows)

        GeometryReader { geo in
            let centerY = (geo.size.height - rowHeight) / 2

            ZStack {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    Text(label(item))
                        .font(index == currentIndex
                              ? selectedFont ?? theme.typography.amount
                              : neighborFont ?? theme.typography.bubble)
                        .foregroundStyle(index == currentIndex
                                         ? theme.palette.textPrimary
                                         : theme.palette.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .frame(width: width, height: rowHeight)
                        .offset(y: centerY + CGFloat(index) * rowHeight + totalOffset)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        isDragging = true
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        guard !items.isEmpty else {
                            isDragging = false
                            return
                        }

                        isDragging = false
                        let velocity = value.predictedEndTranslation.height - value.translation.height
                        let projected = totalOffset + velocity * 0.3
                        let rawIndex = -projected / rowHeight
                        let snapped = max(0, min(items.count - 1, Int(rawIndex.rounded())))

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            baseOffset = -CGFloat(snapped) * rowHeight
                            dragOffset = 0
                        }

                        selection = items[snapped]
                    }
            )
            .onAppear {
                baseOffset = -CGFloat(selectedIndex) * rowHeight
            }
            .onChange(of: selection) { _, _ in
                guard !isDragging else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    baseOffset = -CGFloat(selectedIndex) * rowHeight
                    dragOffset = 0
                }
            }
            .onChange(of: items) { _, newItems in
                guard !isDragging, !newItems.isEmpty else { return }
                let index = newItems.firstIndex(of: selection) ?? 0
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    baseOffset = -CGFloat(index) * rowHeight
                    dragOffset = 0
                }
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .mask(Rectangle())
    }
}

// MARK: - Shared container that wraps a row of wheels

/// Wraps a horizontal row of wheels in one compact raisedSurface pill
/// with a single center selection band that spans every column at once.
struct DrumContainer<Content: View>: View {
    @Environment(\.appTheme) private var theme
    var rowHeight: CGFloat = 40
    var visibleRows: Int = 3
    var columnSpacing: CGFloat = 0
    var horizontalPadding: CGFloat = 8
    var verticalPadding: CGFloat = 4
    var cornerRadius: CGFloat = 26
    var selectionCornerRadius: CGFloat = 18
    var selectionHorizontalPadding: CGFloat = 10
    var selectionLineWidth: CGFloat = 1
    var fillWidth: Bool = false
    var surfaceColor: Color? = nil
    var content: () -> Content

    init(
        rowHeight: CGFloat = 40,
        visibleRows: Int = 3,
        columnSpacing: CGFloat = 0,
        horizontalPadding: CGFloat = 8,
        verticalPadding: CGFloat = 4,
        cornerRadius: CGFloat = 26,
        selectionCornerRadius: CGFloat = 18,
        selectionHorizontalPadding: CGFloat = 10,
        selectionLineWidth: CGFloat = 1,
        fillWidth: Bool = false,
        surfaceColor: Color? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.rowHeight = rowHeight
        self.visibleRows = visibleRows
        self.columnSpacing = columnSpacing
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
        self.cornerRadius = cornerRadius
        self.selectionCornerRadius = selectionCornerRadius
        self.selectionHorizontalPadding = selectionHorizontalPadding
        self.selectionLineWidth = selectionLineWidth
        self.fillWidth = fillWidth
        self.surfaceColor = surfaceColor
        self.content = content
    }

    var body: some View {
        HStack(spacing: columnSpacing) { content() }
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .frame(maxWidth: fillWidth ? .infinity : nil, alignment: .center)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(surfaceColor ?? theme.palette.raisedSurface)
            }
            .overlay(alignment: .center) {
                RoundedRectangle(cornerRadius: selectionCornerRadius, style: .continuous)
                    .strokeBorder(theme.palette.textSecondary, lineWidth: selectionLineWidth)
                    .frame(height: rowHeight)
                    .padding(.horizontal, selectionHorizontalPadding)
                    .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// MARK: - Date wheel (Month / Day / Year)

struct CustomDrumDatePicker: View {
    @Environment(\.appTheme) private var theme
    @Binding var date: Date

    private let calendar = Calendar.current
    private let months = Array(1...12)
    private let years: [Int] = {
        let currentYear = Calendar.current.component(.year, from: .now)
        return Array((currentYear - 5)...(currentYear + 15))
    }()

    @State private var monthSel: Int = 1
    @State private var daySel: Int = 1
    @State private var yearSel: Int = Calendar.current.component(.year, from: .now)

    init(date: Binding<Date>) {
        self._date = date
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date.wrappedValue)
        self._monthSel = State(initialValue: components.month ?? 1)
        self._daySel = State(initialValue: components.day ?? 1)
        self._yearSel = State(initialValue: components.year ?? Calendar.current.component(.year, from: .now))
    }

    var body: some View {
        GeometryReader { proxy in
            let rowHeight: CGFloat = 43
            let horizontalPadding: CGFloat = 14
            let columnSpacing: CGFloat = 10
            let wheelArea = max(260, proxy.size.width - (horizontalPadding * 2) - (columnSpacing * 2))
            let monthWidth = wheelArea * 0.34
            let dayWidth = wheelArea * 0.22
            let yearWidth = wheelArea * 0.34

            DrumContainer(
                rowHeight: rowHeight,
                visibleRows: 3,
                columnSpacing: columnSpacing,
                horizontalPadding: horizontalPadding,
                verticalPadding: 8,
                cornerRadius: 26,
                selectionCornerRadius: 18,
                selectionHorizontalPadding: 12,
                selectionLineWidth: 1.2,
                fillWidth: true,
                surfaceColor: theme.palette.background
            ) {
                CustomDrumWheel(items: months, label: monthShort,
                                selection: $monthSel,
                                width: monthWidth,
                                rowHeight: rowHeight,
                                selectedFont: .system(size: 25, weight: .black, design: .rounded),
                                neighborFont: .system(size: 18, weight: .heavy, design: .rounded))
                CustomDrumWheel(items: daysInSelectedMonth, label: { String($0) },
                                selection: $daySel,
                                width: dayWidth,
                                rowHeight: rowHeight,
                                selectedFont: .system(size: 25, weight: .black, design: .rounded),
                                neighborFont: .system(size: 18, weight: .heavy, design: .rounded))
                CustomDrumWheel(items: years, label: { String($0) },
                                selection: $yearSel,
                                width: yearWidth,
                                rowHeight: rowHeight,
                                selectedFont: .system(size: 25, weight: .black, design: .rounded),
                                neighborFont: .system(size: 18, weight: .heavy, design: .rounded))
            }
        }
        .frame(height: 145)
        .onAppear { syncFromDate() }
        .onChange(of: monthSel) { _, _ in commitDate() }
        .onChange(of: daySel)   { _, _ in commitDate() }
        .onChange(of: yearSel)  { _, _ in commitDate() }
        .onChange(of: date, initial: true) { _, _ in syncFromDate() }
    }

    private var daysInSelectedMonth: [Int] {
        var comps = DateComponents()
        comps.year = yearSel; comps.month = monthSel; comps.day = 1
        guard let d = calendar.date(from: comps),
              let range = calendar.range(of: .day, in: .month, for: d)
        else { return Array(1...31) }
        return Array(range)
    }

    private func monthShort(_ m: Int) -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "LLL"
        var c = DateComponents(); c.month = m; c.day = 1
        return fmt.string(from: calendar.date(from: c) ?? .now)
    }

    private func syncFromDate() {
        let comps = calendar.dateComponents([.year, .month, .day], from: date)
        monthSel = comps.month ?? 1
        daySel   = comps.day ?? 1
        yearSel  = comps.year ?? Calendar.current.component(.year, from: .now)
    }

    private func commitDate() {
        var comps = DateComponents()
        comps.year = yearSel
        comps.month = monthSel
        comps.day = min(daySel, daysInSelectedMonth.last ?? 28)
        if let d = calendar.date(from: comps) { date = d }
    }
}

// MARK: - Month + Year wheel

struct CustomDrumMonthYearPicker: View {
    @Environment(\.appTheme) private var theme
    @Binding var monthYear: Date

    private let calendar = Calendar.current
    private let months = Array(1...12)
    private let years: [Int] = {
        let currentYear = Calendar.current.component(.year, from: .now)
        return Array((currentYear - 10)...(currentYear + 25))
    }()

    @State private var monthSel: Int = 1
    @State private var yearSel: Int = Calendar.current.component(.year, from: .now)

    var body: some View {
        DrumContainer(rowHeight: 40, visibleRows: 3) {
            CustomDrumWheel(items: months, label: monthLong,
                            selection: $monthSel, width: 118)
            CustomDrumWheel(items: years, label: { String($0) },
                            selection: $yearSel, width: 92)
        }
        .onAppear { syncFromDate() }
        .onChange(of: monthSel) { _, _ in commit() }
        .onChange(of: yearSel)  { _, _ in commit() }
        .onChange(of: monthYear) { _, _ in syncFromDate() }
    }

    private func monthLong(_ m: Int) -> String {
        let fmt = DateFormatter(); fmt.dateFormat = "LLLL"
        var c = DateComponents(); c.month = m; c.day = 1
        return fmt.string(from: calendar.date(from: c) ?? .now)
    }

    private func syncFromDate() {
        monthSel = calendar.component(.month, from: monthYear)
        yearSel  = calendar.component(.year,  from: monthYear)
    }

    private func commit() {
        var comps = DateComponents()
        comps.year = yearSel; comps.month = monthSel; comps.day = 1
        if let d = calendar.date(from: comps) { monthYear = d }
    }
}

// MARK: - Time wheel (Hour : Minute AM/PM) — matches the Lurelia reference

struct CustomDrumTimePicker: View {
    @Environment(\.appTheme) private var theme
    @Binding var secondsFromMidnight: Int

    private let hours = Array(1...12)
    private let minutes = Array(0..<60)
    private let periods = ["AM", "PM"]

    @State private var hour: Int = 9
    @State private var minute: Int = 0
    @State private var period: String = "AM"

    init(secondsFromMidnight: Binding<Int>) {
        self._secondsFromMidnight = secondsFromMidnight
        let total = max(0, min(86399, secondsFromMidnight.wrappedValue))
        let hour24 = total / 3600
        self._minute = State(initialValue: (total % 3600) / 60)
        self._period = State(initialValue: hour24 >= 12 ? "PM" : "AM")
        self._hour = State(initialValue: hour24 % 12 == 0 ? 12 : hour24 % 12)
    }

    var body: some View {
        GeometryReader { proxy in
            let rowHeight: CGFloat = 43
            let horizontalPadding: CGFloat = 14
            let columnSpacing: CGFloat = 10
            let colonWidth: CGFloat = 18
            let wheelArea = max(260, proxy.size.width - (horizontalPadding * 2) - (columnSpacing * 3) - colonWidth)
            let hourWidth = wheelArea * 0.25
            let minuteWidth = wheelArea * 0.34
            let periodWidth = wheelArea * 0.41

            DrumContainer(
                rowHeight: rowHeight,
                visibleRows: 3,
                columnSpacing: columnSpacing,
                horizontalPadding: horizontalPadding,
                verticalPadding: 8,
                cornerRadius: 26,
                selectionCornerRadius: 18,
                selectionHorizontalPadding: 12,
                selectionLineWidth: 1.2,
                fillWidth: true,
                surfaceColor: theme.palette.background
            ) {
                CustomDrumWheel(items: hours, label: { String($0) },
                                selection: $hour,
                                width: hourWidth,
                                rowHeight: rowHeight,
                                selectedFont: .system(size: 25, weight: .black, design: .rounded),
                                neighborFont: .system(size: 18, weight: .heavy, design: .rounded))
                Text(":")
                    .font(.system(size: 25, weight: .black, design: .rounded))
                    .foregroundStyle(theme.palette.textPrimary)
                    .frame(width: colonWidth, height: rowHeight * 3)
                CustomDrumWheel(items: minutes,
                                label: { String(format: "%02d", $0) },
                                selection: $minute,
                                width: minuteWidth,
                                rowHeight: rowHeight,
                                selectedFont: .system(size: 25, weight: .black, design: .rounded),
                                neighborFont: .system(size: 18, weight: .heavy, design: .rounded))
                CustomDrumWheel(items: periods, label: { $0 },
                                selection: $period,
                                width: periodWidth,
                                rowHeight: rowHeight,
                                selectedFont: .system(size: 25, weight: .black, design: .rounded),
                                neighborFont: .system(size: 18, weight: .heavy, design: .rounded))
            }
        }
        .frame(height: 145)
        .onAppear { sync() }
        .onChange(of: hour)   { _, _ in commit() }
        .onChange(of: minute) { _, _ in commit() }
        .onChange(of: period) { _, _ in commit() }
        .onChange(of: secondsFromMidnight, initial: true) { _, _ in sync() }
    }

    private func sync() {
        let total = max(0, min(86399, secondsFromMidnight))
        var h24 = total / 3600
        minute = (total % 3600) / 60
        period = h24 >= 12 ? "PM" : "AM"
        h24 = h24 % 12
        hour = h24 == 0 ? 12 : h24
    }

    private func commit() {
        var h24 = hour % 12
        if period == "PM" { h24 += 12 }
        secondsFromMidnight = h24 * 3600 + minute * 60
    }
}
