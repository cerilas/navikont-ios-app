import SwiftUI
import Combine

struct CheckinView: View {
    @Environment(\.colorScheme) var colorScheme
    let checkinTemplateId: String
    let moduleTitle: String
    let onComplete: () -> Void

    @StateObject private var viewModel = CheckinViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            NKColors.bgPrimary(colorScheme).ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage, viewModel.template == nil {
                errorView(message: error)
            } else if let template = viewModel.template {
                checkinContent(template)
            }

            if viewModel.showSuccess {
                successOverlay
            }
        }
        .task {
            await viewModel.load(templateId: checkinTemplateId)
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: NKColors.accentTeal))
                .scaleEffect(1.5)
            Text("Check-in formu yükleniyor...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(NKColors.textSecondary(colorScheme))
        }
    }

    // MARK: - Error

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 44))
                .foregroundColor(NKColors.warning)
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(NKColors.textSecondary(colorScheme))
                .multilineTextAlignment(.center)
            Button("Tekrar Dene") {
                Task { await viewModel.load(templateId: checkinTemplateId) }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(NKColors.accentTeal)
        }
        .padding(30)
    }

    // MARK: - Content

    private func checkinContent(_ template: CheckinTemplate) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(NKColors.textSecondary(colorScheme))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(NKColors.glassBackground(colorScheme)))
                }
                Spacer()
                StreakBadge(count: viewModel.currentStreak)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 8)

            // Title
            VStack(alignment: .leading, spacing: 6) {
                Text(moduleTitle)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(NKColors.textPrimary(colorScheme))
                Text("Bugünkü durumunuzu kaydedin")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(NKColors.textSecondary(colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if let fields = template.fields, !fields.isEmpty {
                        ForEach(fields) { field in
                            CheckinFieldCard(
                                field: field,
                                value: viewModel.values[field.fieldKey ?? field.id.uuidString] ?? "",
                                onValue: { val in
                                    viewModel.setValue(for: field.fieldKey ?? field.id.uuidString, value: val)
                                }
                            )
                        }
                    } else {
                        // Fallback: no fields defined, show a simple daily mood check
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Bugün kendinizi nasıl hissediyorsunuz?")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(NKColors.textPrimary(colorScheme))

                            HStack(spacing: 10) {
                                ForEach(["😔", "😐", "🙂", "😊", "😄"], id: \.self) { emoji in
                                    Button(action: { viewModel.setValue(for: "mood", value: emoji) }) {
                                        Text(emoji)
                                            .font(.system(size: 36))
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 56)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(viewModel.values["mood"] == emoji
                                                          ? NKColors.accentTeal.opacity(0.2)
                                                          : NKColors.glassBackground(colorScheme))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(viewModel.values["mood"] == emoji
                                                                    ? NKColors.accentTeal.opacity(0.5)
                                                                    : Color.clear, lineWidth: 1.5)
                                                    )
                                            )
                                    }
                                    .animation(.spring(response: 0.3), value: viewModel.values["mood"])
                                }
                            }
                        }
                        .padding(18)
                        .glassCard(cornerRadius: 16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }

            // Error message
            if let err = viewModel.errorMessage {
                Text(err)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(NKColors.danger)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
            }

            // Submit button
            Button(action: {
                Task { await viewModel.submit(templateId: checkinTemplateId) }
            }) {
                HStack(spacing: 10) {
                    if viewModel.isSubmitting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Check-in Tamamla")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(NKColors.tealGradient)
                )
                .shadow(color: NKColors.accentTeal.opacity(0.3), radius: 14, y: 6)
            }
            .disabled(viewModel.isSubmitting)
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .ignoresSafeArea()
            
            VStack(spacing: 36) {
                ZStack {
                    Circle()
                        .fill(NKColors.tealGradient)
                        .frame(width: 88, height: 88)
                        .shadow(color: NKColors.accentTeal.opacity(0.4), radius: 24, x: 0, y: 12)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 16)
                
                VStack(spacing: 12) {
                    Text("Check-in Tamamlandı!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if viewModel.streakDay > 0 {
                        StreakBadge(count: viewModel.streakDay)
                            .padding(.vertical, 4)
                    }
                    
                    Text("Günlük verileriniz kaydedildi.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                Button(action: {
                    onComplete()
                    dismiss()
                }) {
                    Text("Devam Et")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(NKColors.bgPrimary(colorScheme))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule()
                                .fill(Color.white)
                                .shadow(color: .white.opacity(0.2), radius: 10, y: 5)
                        )
                }
                .padding(.bottom, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(NKColors.bgCard(colorScheme).opacity(0.7))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .stroke(NKColors.glassBorder(colorScheme), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
            .shadow(color: NKColors.cardShadow(colorScheme), radius: 40, y: 20)
            .transition(.scale(scale: 0.92).combined(with: .opacity))
        }
        .transition(.opacity)
        .zIndex(100)
    }
}

// MARK: - CheckinFieldCard

struct CheckinFieldCard: View {
    @Environment(\.colorScheme) var colorScheme
    let field: CheckinField
    let value: String
    let onValue: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(field.label)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(NKColors.textPrimary(colorScheme))

            switch field.fieldType {
            case "emoji":
                emojiView
            case "scale", "slider":
                scaleView
            case "boolean":
                booleanView
            case "single_choice":
                singleChoiceView
            case "number":
                numberView
            default:
                textView
            }
        }
        .padding(18)
        .glassCard(cornerRadius: 16)
    }

    private var emojiView: some View {
        HStack(spacing: 10) {
            ForEach(["😔", "😐", "🙂", "😊", "😄"], id: \.self) { emoji in
                Button(action: { onValue(emoji) }) {
                    Text(emoji)
                        .font(.system(size: 36))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(value == emoji
                                      ? NKColors.accentTeal.opacity(0.2)
                                      : NKColors.glassBackground(colorScheme))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(value == emoji
                                                ? NKColors.accentTeal.opacity(0.5)
                                                : Color.clear, lineWidth: 1.5)
                                )
                        )
                }
                .animation(.spring(response: 0.3), value: value)
            }
        }
    }

    private var scaleView: some View {
        VStack(spacing: 12) {
            let currentVal = Int(value) ?? 0
            Text("\(currentVal)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundColor(NKColors.accentTeal)
            HStack(spacing: 4) {
                ForEach(0...10, id: \.self) { i in
                    Button(action: { onValue("\(i)") }) {
                        Text("\(i)")
                            .font(.system(size: 12, weight: value == "\(i)" ? .bold : .regular))
                            .foregroundColor(value == "\(i)" ? .white : NKColors.textSecondary(colorScheme))
                            .frame(minWidth: 26, minHeight: 26)
                            .background(Circle().fill(value == "\(i)" ? NKColors.accentTeal : NKColors.glassBackground(colorScheme)))
                    }
                }
            }
        }
    }

    private var booleanView: some View {
        HStack(spacing: 12) {
            ForEach(["Evet", "Hayır"], id: \.self) { option in
                Button(action: { onValue(option == "Evet" ? "true" : "false") }) {
                    Text(option)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(value == (option == "Evet" ? "true" : "false") ? .white : NKColors.textSecondary(colorScheme))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(value == (option == "Evet" ? "true" : "false") ? NKColors.accentTeal : NKColors.glassBackground(colorScheme))
                        )
                }
            }
        }
    }

    private var singleChoiceView: some View {
        VStack(spacing: 8) {
            ForEach(field.options ?? [], id: \.id) { option in
                let optionVal = option.value ?? option.id.uuidString
                Button(action: { onValue(optionVal) }) {
                    HStack {
                        Text(option.label)
                            .font(.system(size: 14, weight: value == optionVal ? .semibold : .regular))
                            .foregroundColor(value == optionVal ? NKColors.textPrimary(colorScheme) : NKColors.textSecondary(colorScheme))
                        Spacer()
                        if value == optionVal {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(NKColors.accentTeal)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(value == optionVal ? NKColors.accentTeal.opacity(0.12) : NKColors.glassBackground(colorScheme))
                    )
                }
            }
        }
    }

    private var numberView: some View {
        HStack {
            TextField("", text: Binding(get: { value }, set: { onValue($0) }),
                      prompt: Text("0").foregroundColor(NKColors.textTertiary(colorScheme)))
                .foregroundColor(NKColors.textPrimary(colorScheme))
                .keyboardType(.decimalPad)
                .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(NKColors.glassBackground(colorScheme))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(NKColors.glassBorder(colorScheme), lineWidth: 1))
        )
    }

    private var textView: some View {
        TextField("", text: Binding(get: { value }, set: { onValue($0) }),
                  prompt: Text(field.placeholder ?? "Cevabınızı yazın...").foregroundColor(NKColors.textTertiary(colorScheme)))
            .foregroundColor(NKColors.textPrimary(colorScheme))
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(NKColors.glassBackground(colorScheme))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(NKColors.glassBorder(colorScheme), lineWidth: 1))
            )
    }
}

// MARK: - ViewModel

@MainActor
class CheckinViewModel: ObservableObject {
    @Published var template: CheckinTemplate?
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var values: [String: String] = [:]
    @Published var showSuccess = false
    @Published var streakDay = 0
    @Published var currentStreak = 0

    private let service = CheckinService()

    func load(templateId: String) async {
        isLoading = true
        errorMessage = nil
        do {
            template = try await service.fetchCheckinTemplate(templateId: templateId)
        } catch {
            errorMessage = "Check-in formu yüklenemedi"
        }
        isLoading = false
    }

    func setValue(for key: String, value: String) {
        values[key] = value
    }

    func submit(templateId: String) async {
        isSubmitting = true
        errorMessage = nil
        let payload = values.map { key, value in ["fieldKey": key, "value": value] }
        do {
            let result = try await service.submitCheckin(templateId: templateId, values: payload)
            streakDay = result.streakCount ?? 0
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showSuccess = true
            }
        } catch {
            errorMessage = "Gönderilemedi: \(error.localizedDescription)"
        }
        isSubmitting = false
    }
}
