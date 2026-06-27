import SwiftUI

struct NotificationSettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    // Save settings locally using AppStorage
    @AppStorage("notif_daily_reminders") private var dailyReminders: Bool = true
    @AppStorage("notif_email_alerts") private var emailAlerts: Bool = false
    @AppStorage("notif_silent_mode") private var silentMode: Bool = false
    @AppStorage("notif_water_reminder") private var waterReminder: Bool = false
    
    var body: some View {
        ZStack {
            NKColors.bgPrimary(colorScheme).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppStrings.t("Uygulama Bildirimleri"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(NKColors.textSecondary(colorScheme))
                            .padding(.leading, 16)
                            .textCase(.uppercase)
                        
                        VStack(spacing: 0) {
                            NotificationToggleRow(
                                icon: "bell.badge.fill",
                                color: .orange,
                                title: AppStrings.t("Günlük Hatırlatıcılar"),
                                subtitle: AppStrings.t("Görev ve egzersiz hatırlatmaları"),
                                isOn: $dailyReminders
                            )
                            
                            Divider()
                                .background(NKColors.glassBackground(colorScheme))
                                .padding(.leading, 60)
                            
                            NotificationToggleRow(
                                icon: "drop.fill",
                                color: .cyan,
                                title: AppStrings.t("Su İçme Hatırlatıcıları"),
                                subtitle: AppStrings.t("Düzenli sıvı alımı takibi"),
                                isOn: $waterReminder
                            )
                            
                            Divider()
                                .background(NKColors.glassBackground(colorScheme))
                                .padding(.leading, 60)
                            
                            NotificationToggleRow(
                                icon: "speaker.slash.fill",
                                color: .purple,
                                title: AppStrings.t("Sessiz Mod"),
                                subtitle: AppStrings.t("Bildirimleri sessiz al"),
                                isOn: $silentMode
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(NKColors.glassBackground(colorScheme))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
                        )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppStrings.t("Diğer Bildirimler"))
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(NKColors.textSecondary(colorScheme))
                            .padding(.leading, 16)
                            .textCase(.uppercase)
                        
                        VStack(spacing: 0) {
                            NotificationToggleRow(
                                icon: "envelope.fill",
                                color: .blue,
                                title: AppStrings.t("E-posta Bültenleri"),
                                subtitle: AppStrings.t("Haftalık raporlar ve makaleler"),
                                isOn: $emailAlerts
                            )
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(NKColors.glassBackground(colorScheme))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
                        )
                    }
                    
                    Text(AppStrings.t("Bu ayarlar telefonunuzun yerleşik hafızasında güvenle saklanmaktadır."))
                        .font(.system(size: 13))
                        .foregroundColor(NKColors.textTertiary(colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.top, 16)
                        .padding(.horizontal, 32)
                }
                .padding(20)
            }
        }
        .navigationTitle("Bildirimler")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationToggleRow: View {
    @Environment(\.colorScheme) var colorScheme
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(NKColors.textPrimary(colorScheme))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(NKColors.textTertiary(colorScheme))
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(color)
        }
        .padding(16)
    }
}
