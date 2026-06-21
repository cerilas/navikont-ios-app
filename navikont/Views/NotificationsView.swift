import SwiftUI
import Combine

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    var unreadCount: Int {
        notifications.filter { $0.readAt == nil }.count
    }
    
    func fetchNotifications() async {
        if notifications.isEmpty {
            isLoading = true
        }
        errorMessage = nil
        do {
            let fetched: [AppNotification] = try await NetworkManager.shared.get("/api/patient/notifications")
            self.notifications = fetched
            isLoading = false
        } catch let error as NetworkError {
            if case .networkFailure(let nsError) = error {
                let err = nsError as NSError
                if err.domain == NSURLErrorDomain && err.code == NSURLErrorCancelled {
                    isLoading = false
                    return
                }
            }
            self.errorMessage = error.errorDescription
            isLoading = false
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                isLoading = false
                return
            }
            self.errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func markAsRead(_ notification: AppNotification) async {
        guard notification.readAt == nil else { return }
        
        // Optimistic UI update
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            let updated = AppNotification(
                id: notification.id,
                title: notification.title,
                body: notification.body,
                createdAt: notification.createdAt,
                readAt: Date(),
                status: "read"
            )
            notifications[index] = updated
        }
        
        // Network call
        do {
            let _: EmptyResponse = try await NetworkManager.shared.put("/api/patient/notifications/\(notification.id)/read")
        } catch {
            print("Failed to mark notification as read: \(error)")
        }
    }
}

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedNotification: AppNotification?
    
    @State private var scrollOffset: CGFloat = 0
    @State private var isRefreshing = false
    
    // UI Helpers
    private var primaryColor: Color { Color(hex: "06B6D4") }
    
    var body: some View {
        ZStack {
            NKColors.bgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: primaryColor))
                        .scaleEffect(1.5)
                    Spacer()
                } else if let error = viewModel.errorMessage {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        Text(error)
                            .font(.system(size: 15))
                            .foregroundColor(NKColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Tekrar Dene") {
                            Task { await viewModel.fetchNotifications() }
                        }
                        .foregroundColor(primaryColor)
                        .padding(.top, 8)
                    }
                    Spacer()
                } else if viewModel.notifications.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 50))
                            .foregroundColor(NKColors.textTertiary.opacity(0.5))
                        Text("Henüz hiç bildiriminiz yok.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(NKColors.textSecondary)
                    }
                    Spacer()
                } else {
                    // Custom Refresh Indicator removed from here to prevent layout jumps
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.notifications) { notification in
                                NotificationRow(notification: notification)
                                    .onTapGesture {
                                        Task {
                                            await viewModel.markAsRead(notification)
                                        }
                                        selectedNotification = notification
                                    }
                            }
                        }
                        .padding(16)
                    }
                    .refreshable {
                        isRefreshing = true
                        await viewModel.fetchNotifications()
                        isRefreshing = false
                    }
                }
            }
        }
        .navigationTitle("Bildirimler")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchNotifications()
        }
        .sheet(item: $selectedNotification) { notification in
            NotificationDetailView(notification: notification)
        }
    }
}

struct NotificationRow: View {
    let notification: AppNotification
    
    private var isUnread: Bool {
        notification.readAt == nil
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            Circle()
                .fill(isUnread ? Color(hex: "06B6D4").opacity(0.2) : Color.white.opacity(0.05))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: isUnread ? "bell.badge.fill" : "bell.fill")
                        .foregroundColor(isUnread ? Color(hex: "06B6D4") : NKColors.textTertiary)
                        .font(.system(size: 16))
                )
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(notification.title)
                        .font(.system(size: 16, weight: isUnread ? .bold : .semibold))
                        .foregroundColor(isUnread ? NKColors.textPrimary : NKColors.textSecondary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text(timeAgo(from: notification.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(NKColors.textTertiary)
                }
                
                Text(notification.body)
                    .font(.system(size: 14))
                    .foregroundColor(isUnread ? NKColors.textSecondary : NKColors.textTertiary)
                    .lineLimit(3)
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .background(isUnread ? Color(hex: "06B6D4").opacity(0.05) : Color.white.opacity(0.02))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isUnread ? Color(hex: "06B6D4").opacity(0.3) : Color.white.opacity(0.05), lineWidth: 1)
        )
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct NotificationDetailView: View {
    let notification: AppNotification
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                NKColors.bgPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Header
                        HStack(alignment: .top) {
                            Circle()
                                .fill(Color(hex: "06B6D4").opacity(0.1))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "bell.fill")
                                        .foregroundColor(Color(hex: "06B6D4"))
                                        .font(.system(size: 20))
                                )
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(notification.title)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(NKColors.textPrimary)
                                
                                Text(formattedDate(notification.createdAt))
                                    .font(.system(size: 13))
                                    .foregroundColor(NKColors.textTertiary)
                            }
                            .padding(.leading, 8)
                        }
                        
                        Divider()
                            .background(Color.white.opacity(0.1))
                        
                        // Body
                        Text(notification.body)
                            .font(.system(size: 16))
                            .foregroundColor(NKColors.textSecondary)
                            .lineSpacing(6)
                            
                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                    .foregroundColor(Color(hex: "06B6D4"))
                    .font(.system(size: 16, weight: .semibold))
                }
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
