import SwiftUI

struct CalendarDayDetailsPopup: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var viewModel: DashboardViewModel
    let dateString: String
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private var displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy, EEEE"
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter
    }()
    
    init(viewModel: DashboardViewModel, dateString: String) {
        self.viewModel = viewModel
        self.dateString = dateString
    }
    
    var body: some View {
        ZStack {
            NKColors.bgPrimary(colorScheme).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                if let date = dateFormatter.date(from: dateString) {
                    Text(displayFormatter.string(from: date))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(NKColors.textPrimary(colorScheme))
                        .padding(.top, 24)
                }
                
                if viewModel.isDayDetailsLoading {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(NKColors.accentTeal)
                    Spacer()
                } else if let details = viewModel.selectedDayDetails {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {
                            
                            // Scheduled Tasks Summary
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Programın \(details.targetDayNumber). Günü")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(NKColors.textSecondary(colorScheme))
                                
                                let status = getTargetDayStatus(details: details)
                                
                                HStack(spacing: 16) {
                                    Image(systemName: status.isCompleted ? "checkmark.circle.fill" : (details.scheduledTasks.isEmpty ? "minus.circle.fill" : "xmark.circle.fill"))
                                        .foregroundColor(status.isCompleted ? NKColors.success : (details.scheduledTasks.isEmpty ? NKColors.textTertiary(colorScheme) : NKColors.danger))
                                        .font(.system(size: 32))
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        if details.scheduledTasks.isEmpty {
                                            Text("Görev Yok")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(NKColors.textPrimary(colorScheme))
                                            Text("Bu güne atanmış bir görev bulunmuyor.")
                                                .font(.system(size: 14))
                                                .foregroundColor(NKColors.textSecondary(colorScheme))
                                        } else {
                                            Text(status.isCompleted ? "Tamamlandı" : "Eksik / Yapılmadı")
                                                .font(.system(size: 16, weight: .bold))
                                                .foregroundColor(status.isCompleted ? NKColors.success : NKColors.danger)
                                            
                                            if status.isCompleted, let dateStr = status.completedDateStr {
                                                Text("\(dateStr) tarihinde çözüldü")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(NKColors.textSecondary(colorScheme))
                                            }
                                        }
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(NKColors.bgCardLight(colorScheme))
                                .cornerRadius(16)
                            }
                            
                            // Extra Days Summary
                            let extraDays = getExtraDays(details: details)
                            if !extraDays.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    Text("Ayrıca Bu Tarihte Çözülenler")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(NKColors.accentAmber)
                                    
                                    ForEach(extraDays, id: \.self) { dayNum in
                                        HStack(spacing: 16) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(NKColors.success)
                                                .font(.system(size: 24))
                                            
                                            Text("Programın \(dayNum). Günü görevleri çözüldü")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundColor(NKColors.textPrimary(colorScheme))
                                        }
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(NKColors.bgCardLight(colorScheme))
                                        .cornerRadius(16)
                                    }
                                }
                            }
                            
                        }
                        .padding(20)
                    }
                } else {
                    Spacer()
                    Text("Veri yüklenemedi.")
                        .foregroundColor(NKColors.danger)
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func getTargetDayStatus(details: CalendarDayDetailsResponse) -> (isCompleted: Bool, completedDateStr: String?) {
        if details.scheduledTasks.isEmpty {
            return (false, nil)
        }
        
        let requiredTasks = details.scheduledTasks.filter { $0.isRequired }
        let allCompleted = (requiredTasks.isEmpty ? details.scheduledTasks : requiredTasks).allSatisfy { $0.isCompleted }
        
        var completedDateStr: String? = nil
        if allCompleted {
            // Find the latest completion date
            let dates = details.scheduledTasks.compactMap { task -> Date? in
                guard let dateStr = task.completedAt else { return nil }
                
                // Try ISO8601 parsing
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let d = formatter.date(from: dateStr) { return d }
                
                let formatter2 = ISO8601DateFormatter()
                return formatter2.date(from: dateStr)
            }
            
            if let maxDate = dates.max() {
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMMM yyyy"
                formatter.locale = Locale(identifier: "tr_TR")
                completedDateStr = formatter.string(from: maxDate)
            }
        }
        
        return (allCompleted, completedDateStr)
    }
    
    private func getExtraDays(details: CalendarDayDetailsResponse) -> [Int] {
        let days = details.extraCompletedTasks.map { $0.originalDayNumber }
        return Array(Set(days)).sorted()
    }
}
