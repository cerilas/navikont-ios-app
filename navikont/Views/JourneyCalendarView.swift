import SwiftUI

struct SelectedDateItem: Identifiable {
    let id = UUID()
    let dateString: String
}

struct JourneyCalendarView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedDateItem: SelectedDateItem?
    
    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    // Group days by year and month
    private var groupedMonths: [(title: String, days: [CalendarDay])] {
        guard let calendarData = viewModel.calendarResponse else { return [] }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMMM yyyy"
        displayFormatter.locale = Locale(identifier: "tr_TR")
        
        var groups: [String: [CalendarDay]] = [:]
        
        for day in calendarData.days {
            if let date = formatter.date(from: day.date) {
                let monthString = displayFormatter.string(from: date)
                groups[monthString, default: []].append(day)
            }
        }
        
        // Sort months based on the first day's date in each group
        return groups.map { (title: $0.key, days: $0.value) }
            .sorted { group1, group2 in
                guard let d1 = group1.days.first?.date,
                      let d2 = group2.days.first?.date,
                      let date1 = formatter.date(from: d1),
                      let date2 = formatter.date(from: d2) else { return false }
                return date1 < date2
            }
    }
    
    var body: some View {
        ZStack {
            NKColors.bgGradient(colorScheme).edgesIgnoringSafeArea(.all)
            
            if viewModel.calendarResponse == nil {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Program Takvimi")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(NKColors.textPrimary(colorScheme))
                            
                            Text("Programa katılımınızdan itibaren ilerlemeniz")
                                .font(.system(size: 15))
                                .foregroundColor(NKColors.textSecondary(colorScheme))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Month Groups
                        ForEach(groupedMonths, id: \.title) { group in
                            monthSection(title: group.title, days: group.days)
                        }
                        
                        // Legend
                        legendSection
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.fetchCalendarData()
            }
        }
        .sheet(item: $selectedDateItem) { item in
            if #available(iOS 16.0, *) {
                CalendarDayDetailsPopup(viewModel: viewModel, dateString: item.dateString)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            } else {
                CalendarDayDetailsPopup(viewModel: viewModel, dateString: item.dateString)
            }
        }
    }
    
    // MARK: - Subviews
    
    private func monthSection(title: String, days: [CalendarDay]) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title.capitalized)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(NKColors.textPrimary(colorScheme))
                .padding(.horizontal, 20)
            
            VStack(spacing: 8) {
                // Weekday headers
                HStack(spacing: 8) {
                    let weekdays = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(NKColors.textSecondary(colorScheme))
                            .frame(maxWidth: .infinity)
                    }
                }
                
                // Calendar Grid
                LazyVGrid(columns: columns, spacing: 12) {
                    // Empty cells for first day padding
                    let firstDayOffset = calculateOffset(for: days.first)
                    ForEach(0..<firstDayOffset, id: \.self) { _ in
                        Color.clear.frame(height: 44)
                    }
                    
                    // Actual days
                    ForEach(days) { day in
                        dayCell(for: day)
                            .onTapGesture {
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                                if let date = formatter.date(from: day.date) {
                                    let reqFormatter = DateFormatter()
                                    reqFormatter.dateFormat = "yyyy-MM-dd"
                                    let dateStr = reqFormatter.string(from: date)
                                    viewModel.fetchDayDetails(date: dateStr)
                                    selectedDateItem = SelectedDateItem(dateString: dateStr)
                                }
                            }
                    }
                }
            }
            .padding(20)
            .background(NKColors.bgCard(colorScheme))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
            )
            .shadow(color: NKColors.cardShadow(colorScheme), radius: 10, x: 0, y: 4)
            .padding(.horizontal, 20)
        }
    }
    
    private func dayCell(for day: CalendarDay) -> some View {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let date = formatter.date(from: day.date) ?? Date()
        let dayOfMonth = calendar.component(.day, from: date)
        
        return VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(backgroundColor(for: day.status))
                    .frame(width: 40, height: 40)
                
                if day.status == .current {
                    Circle()
                        .strokeBorder(NKColors.accentTeal, lineWidth: 2)
                        .frame(width: 44, height: 44)
                }
                
                Text("\(dayOfMonth)")
                    .font(.system(size: 15, weight: day.status == .current ? .bold : .medium))
                    .foregroundColor(textColor(for: day.status))
            }
            
            // Status Icon and Program Day text
            ZStack(alignment: .top) {
                // Background shadow pill for status
                Capsule()
                    .fill(NKColors.bgCardLight(colorScheme))
                    .frame(width: 38, height: 16)
                    .shadow(color: NKColors.cardShadow(colorScheme), radius: 2, x: 0, y: 1)
                
                HStack(spacing: 2) {
                    if day.status == .completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(NKColors.success)
                            .font(.system(size: 9))
                    } else if day.status == .missed {
                        Circle()
                            .fill(Color.red.opacity(0.8))
                            .frame(width: 6, height: 6)
                    } else if day.status == .current {
                        Circle()
                            .fill(NKColors.accentTeal)
                            .frame(width: 6, height: 6)
                    } else {
                        Circle()
                            .fill(NKColors.glassBackground(colorScheme))
                            .frame(width: 6, height: 6)
                    }
                    
                    Text("\(day.dayNumber).G")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(NKColors.textSecondary(colorScheme))
                }
                .offset(y: 2)
            }
            .offset(y: -10)
        }
        .frame(height: 56)
    }
    
    private var legendSection: some View {
        HStack(spacing: 20) {
            legendItem(color: NKColors.success, text: "Tamamlandı")
            legendItem(color: Color.red.opacity(0.8), text: "Eksik")
            legendItem(color: NKColors.accentTeal, text: "Bugün")
        }
        .padding(.top, 20)
    }
    
    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(NKColors.textSecondary(colorScheme))
        }
    }
    
    // MARK: - Helpers
    
    private func calculateOffset(for day: CalendarDay?) -> Int {
        guard let day = day else { return 0 }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: day.date) else { return 0 }
        
        // Sunday = 1, Monday = 2... We want Monday = 0, Sunday = 6
        let weekday = calendar.component(.weekday, from: date)
        return (weekday + 5) % 7
    }
    
    private func backgroundColor(for status: CalendarDay.DayStatus) -> Color {
        switch status {
        case .completed:
            return NKColors.success.opacity(0.15)
        case .missed:
            return Color.red.opacity(0.1)
        case .current:
            return NKColors.accentTeal.opacity(0.15)
        case .future:
            return Color.white.opacity(0.05)
        }
    }
    
    private func textColor(for status: CalendarDay.DayStatus) -> Color {
        switch status {
        case .completed:
            return NKColors.textPrimary(colorScheme)
        case .missed:
            return NKColors.textPrimary(colorScheme)
        case .current:
            return NKColors.accentTeal
        case .future:
            return NKColors.textTertiary(colorScheme)
        }
    }
}
