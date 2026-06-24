import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var activeEnrollment: Enrollment?
    @Published var todayTasks: [JourneyStep] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var streakCount: Int = 0
    @Published var calendarResponse: CalendarResponse?
    
    @Published var selectedDayDetails: CalendarDayDetailsResponse?
    @Published var isDayDetailsLoading: Bool = false
    @Published var unreadNotifications: Int = 0

    var allRequiredTasksCompleted: Bool {
        let requiredTasks = todayTasks.filter { $0.required }
        if requiredTasks.isEmpty { return true }
        return requiredTasks.allSatisfy { $0.isCompleted }
    }

    private let dashboardService = DashboardService()
    private let moduleService = ModuleService()

    func loadDashboard() {
        Task {
            await MainActor.run {
                isLoading = true
                errorMessage = nil
            }
            await fetchDashboardData()
            await fetchCalendarData()
        }
    }

    func reloadDashboard() async {
        await MainActor.run {
            errorMessage = nil
        }
        await fetchDashboardData()
    }

    private func fetchDashboardData() async {
        do {
            let response = try await dashboardService.fetchDashboard()

            await MainActor.run {
                self.activeEnrollment = response.mappedEnrollment
                self.todayTasks = response.todayTasks ?? []
                self.streakCount = response.streakCount
                self.unreadNotifications = response.unreadNotifications
                self.isLoading = false
            }
        } catch let error as NetworkError {
            if case .networkFailure(let nsError) = error {
                let err = nsError as NSError
                if err.domain == NSURLErrorDomain && err.code == NSURLErrorCancelled {
                    await MainActor.run { self.isLoading = false }
                    return
                }
            }
            await MainActor.run {
                self.errorMessage = error.errorDescription
                self.isLoading = false
            }
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                await MainActor.run { self.isLoading = false }
                return
            }
            await MainActor.run {
                self.errorMessage = "Veri yüklenemedi: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    func fetchCalendarData() async {
        do {
            let response = try await dashboardService.fetchCalendar()
            await MainActor.run {
                self.calendarResponse = response
            }
        } catch {
            print("Failed to fetch calendar: \(error)")
        }
    }
    
    func fetchDayDetails(date: String) {
        Task {
            await MainActor.run {
                self.isDayDetailsLoading = true
                self.selectedDayDetails = nil
            }
            do {
                let details = try await dashboardService.fetchCalendarDayDetails(date: date)
                await MainActor.run {
                    self.selectedDayDetails = details
                    self.isDayDetailsLoading = false
                }
            } catch {
                print("Failed to fetch day details: \(error)")
                await MainActor.run {
                    self.isDayDetailsLoading = false
                }
            }
        }
    }

    func refreshTodayTasks() {
        Task {
            do {
                let tasks = try await dashboardService.fetchTodayTasks()
                await MainActor.run {
                    self.todayTasks = tasks
                }
            } catch {
                // Silently fail on refresh, keep existing data
                #if DEBUG
                print("⚠️ Failed to refresh today tasks: \(error)")
                #endif
            }
        }
    }

    func markTaskCompleted(taskId: UUID) {
        if let index = todayTasks.firstIndex(where: { $0.id == taskId }) {
            todayTasks[index].isCompleted = true
        }
    }

    func completeModule(enrollmentId: UUID, moduleVersionId: UUID, resultData: [String: Any]? = nil) async -> Bool {
        do {
            let success = try await moduleService.submitModuleProgress(
                enrollmentId: enrollmentId,
                moduleVersionId: moduleVersionId,
                resultData: resultData
            )
            return success
        } catch {
            #if DEBUG
            print("⚠️ Failed to complete module: \(error)")
            #endif
            return false
        }
    }

    func updateCurrentDay(to day: Int) {
        isLoading = true
        Task {
            do {
                _ = try await dashboardService.updateCurrentDay(to: day)
                self.loadDashboard()
            } catch {
                await MainActor.run {
                    self.errorMessage = "Güncellenemedi: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}
