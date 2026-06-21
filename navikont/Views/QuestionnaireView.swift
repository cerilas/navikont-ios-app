import SwiftUI
import Combine

struct QuestionnaireView: View {
    let questionnaireVersionId: UUID
    let moduleTitle: String
    let onComplete: () -> Void

    @StateObject private var viewModel = QuestionnaireViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            NKColors.bgPrimary.ignoresSafeArea()

            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.errorMessage {
                errorView(message: error)
            } else if let questionnaire = viewModel.questionnaire {
                questionnaireContent(questionnaire)
            }

            // Submit success overlay
            if viewModel.showSuccess {
                successOverlay
            }
        }
        .task {
            await viewModel.load(versionId: questionnaireVersionId)
        }
        .onChange(of: viewModel.showSuccess) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    onComplete()
                }
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: NKColors.primaryGradientStart))
                .scaleEffect(1.5)
            Text("Anket yükleniyor...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(NKColors.textSecondary)
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
                .foregroundColor(NKColors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Tekrar Dene") {
                Task { await viewModel.load(versionId: questionnaireVersionId) }
            }
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(NKColors.primaryGradientStart)
        }
        .padding(30)
    }

    // MARK: - Questionnaire Content

    private func questionnaireContent(_ questionnaire: QuestionnaireVersion) -> some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(NKColors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                Spacer()
                Text("\(viewModel.currentPage + 1)/\(questionnaire.questions?.count ?? 1)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(NKColors.textSecondary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 4)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(NKColors.primaryGradient)
                        .frame(width: geo.size.width * viewModel.progress, height: 4)
                        .animation(.spring(response: 0.4), value: viewModel.progress)
                }
            }
            .frame(height: 4)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            // Questions
            ScrollView(showsIndicators: false) {
                if let questions = questionnaire.questions, !questions.isEmpty {
                    let question = questions[viewModel.currentPage]
                    QuestionCard(
                        question: question,
                        answer: viewModel.answers[question.id.uuidString] ?? "",
                        onAnswer: { value in
                            viewModel.setAnswer(for: question.id.uuidString, value: value)
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }

            Spacer()

            // Navigation buttons
            HStack(spacing: 12) {
                if viewModel.currentPage > 0 {
                    Button(action: { viewModel.goBack() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Geri")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(NKColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.08))
                        )
                    }
                }

                Button(action: {
                    let total = questionnaire.questions?.count ?? 1
                    if viewModel.currentPage < total - 1 {
                        viewModel.goNext()
                    } else {
                        Task { await viewModel.submit(versionId: questionnaireVersionId) }
                    }
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            let total = questionnaire.questions?.count ?? 1
                            let isLast = viewModel.currentPage >= total - 1
                            Text(isLast ? "Gönder" : "İleri")
                            Image(systemName: isLast ? "checkmark" : "chevron.right")
                        }
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(NKColors.primaryGradient)
                    )
                    .shadow(color: NKColors.primaryGradientStart.opacity(0.3), radius: 10, y: 5)
                }
                .disabled(viewModel.isSubmitting || !viewModel.canProceed)
                .opacity(viewModel.canProceed ? 1.0 : 0.5)
            }
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
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "34D399"), Color(hex: "059669")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                        .shadow(color: Color(hex: "34D399").opacity(0.4), radius: 24, x: 0, y: 12)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 16)
                
                VStack(spacing: 12) {
                    Text("Anket Tamamlandı")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Cevaplarınız güvenle kaydedildi.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(Color(hex: "1C1C1E").opacity(0.7))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 36, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 32)
            .shadow(color: Color.black.opacity(0.4), radius: 40, y: 20)
            .transition(.scale(scale: 0.92).combined(with: .opacity))
        }
        .transition(.opacity)
        .zIndex(100)
    }
}

// MARK: - Question Card

struct QuestionCard: View {
    let question: Question
    let answer: String
    let onAnswer: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Question label
            VStack(alignment: .leading, spacing: 6) {
                if question.isRequired == true {
                    Text("Zorunlu")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(NKColors.accentRose)
                        .tracking(1)
                }
                Text(question.label)
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(NKColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Input based on type
            switch question.questionType {
            case "single_choice":
                singleChoiceView
            case "scale":
                scaleView
            case "text":
                textInputView(multiline: false)
            case "textarea":
                textInputView(multiline: true)
            case "number":
                numberInputView
            case "boolean":
                booleanView
            default:
                textInputView(multiline: false)
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 18)
        .padding(.bottom, 8)
    }

    // Single choice (radio buttons)
    private var singleChoiceView: some View {
        VStack(spacing: 10) {
            ForEach(question.options ?? [], id: \.id) { option in
                let optionVal = option.value ?? option.id.uuidString
                Button(action: { onAnswer(optionVal) }) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .stroke(answer == optionVal ? NKColors.primaryGradientStart : Color.white.opacity(0.2), lineWidth: 2)
                                .frame(width: 24, height: 24)
                            if answer == optionVal {
                                Circle()
                                    .fill(NKColors.primaryGradientStart)
                                    .frame(width: 14, height: 14)
                                    .transition(.scale)
                            }
                        }
                        Text(option.label)
                            .font(.system(size: 15, weight: answer == optionVal ? .semibold : .regular))
                            .foregroundColor(answer == optionVal ? NKColors.textPrimary : NKColors.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(answer == optionVal ? NKColors.primaryGradientStart.opacity(0.12) : Color.white.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(answer == optionVal ? NKColors.primaryGradientStart.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: answer)
            }
        }
    }

    // Scale 0-10
    private var scaleView: some View {
        VStack(spacing: 16) {
            let currentVal = Int(answer) ?? 5
            Text("\(currentVal)")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(NKColors.primaryGradientStart)

            HStack(spacing: 6) {
                ForEach(0...10, id: \.self) { i in
                    Button(action: { onAnswer("\(i)") }) {
                        Text("\(i)")
                            .font(.system(size: 13, weight: answer == "\(i)" ? .bold : .regular))
                            .foregroundColor(answer == "\(i)" ? .white : NKColors.textSecondary)
                            .frame(minWidth: 28, minHeight: 28)
                            .background(
                                Circle()
                                    .fill(answer == "\(i)" ? NKColors.primaryGradientStart : Color.white.opacity(0.08))
                            )
                    }
                }
            }

            HStack {
                Text("Hiç etkilemiyor")
                    .font(.system(size: 11))
                    .foregroundColor(NKColors.textTertiary)
                Spacer()
                Text("Çok etkiliyor")
                    .font(.system(size: 11))
                    .foregroundColor(NKColors.textTertiary)
            }
        }
    }

    // Text / Textarea
    private func textInputView(multiline: Bool) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
                .frame(minHeight: multiline ? 100 : 50)

            TextField("", text: Binding(
                get: { answer },
                set: { onAnswer($0) }
            ), prompt: Text(question.placeholder ?? "Cevabınızı yazın...")
                .foregroundColor(NKColors.textTertiary)
            )
            .foregroundColor(NKColors.textPrimary)
            .padding(14)
        }
    }

    // Number
    private var numberInputView: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                .frame(height: 50)
            TextField("", text: Binding(get: { answer }, set: { onAnswer($0) }),
                      prompt: Text("0").foregroundColor(NKColors.textTertiary))
                .foregroundColor(NKColors.textPrimary)
                .keyboardType(.numberPad)
                .padding(14)
        }
    }

    // Boolean (Yes/No)
    private var booleanView: some View {
        HStack(spacing: 12) {
            ForEach(["Evet", "Hayır"], id: \.self) { option in
                Button(action: { onAnswer(option == "Evet" ? "true" : "false") }) {
                    Text(option)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(answer == (option == "Evet" ? "true" : "false") ? .white : NKColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(answer == (option == "Evet" ? "true" : "false")
                                      ? NKColors.primaryGradientStart
                                      : Color.white.opacity(0.06))
                        )
                }
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
class QuestionnaireViewModel: ObservableObject {
    @Published var questionnaire: QuestionnaireVersion?
    @Published var isLoading = false
    @Published var isSubmitting = false
    @Published var errorMessage: String?
    @Published var currentPage = 0
    @Published var answers: [String: String] = [:]
    @Published var showSuccess = false

    private let service = QuestionnaireService()

    var progress: Double {
        let total = questionnaire?.questions?.count ?? 1
        return Double(currentPage + 1) / Double(total)
    }

    var canProceed: Bool {
        guard let questions = questionnaire?.questions, questions.indices.contains(currentPage) else {
            return true
        }
        let question = questions[currentPage]
        if question.required {
            let answer = answers[question.id.uuidString] ?? ""
            return !answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return true
    }

    func load(versionId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            questionnaire = try await service.fetchQuestionnaire(versionId: versionId)
        } catch {
            errorMessage = "Anket yüklenemedi: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func setAnswer(for key: String, value: String) {
        answers[key] = value
    }

    func goNext() {
        let total = questionnaire?.questions?.count ?? 1
        if currentPage < total - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentPage += 1
            }
        }
    }

    func goBack() {
        if currentPage > 0 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentPage -= 1
            }
        }
    }

    func submit(versionId: UUID) async {
        isSubmitting = true
        var payload: [[String: Any]] = []
        
        for (qIdStr, value) in answers {
            var score = 0
            if let q = questionnaire?.questions?.first(where: { $0.id.uuidString == qIdStr }),
               let opt = q.options?.first(where: { ($0.value ?? $0.id.uuidString) == value }) {
                if let scoreStr = opt.score?.stringValue, let s = Int(scoreStr) {
                    score = s
                } else if let s = opt.score?.intValue {
                    score = s
                }
            }
            payload.append([
                "questionId": qIdStr,
                "answerValue": value,
                "score": score
            ])
        }
        do {
            _ = try await service.submitQuestionnaire(versionId: versionId, answers: payload)
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showSuccess = true
            }
        } catch {
            errorMessage = "Gönderim başarısız: \(error.localizedDescription)"
        }
        isSubmitting = false
    }
}
