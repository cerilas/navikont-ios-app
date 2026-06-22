import SwiftUI

struct HealthProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authService: AuthService
    
    @State private var birthDate: Date = Date()
    @State private var gender: String = "Erkek"
    @State private var heightCm: String = ""
    @State private var weightKg: String = ""
    @State private var bloodType: String = "A+"
    
    @State private var selectedDiseaseIds: Set<String> = []
    @State private var allDiseases: [Disease] = []
    
    @State private var isSaving = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    let genders = ["Erkek", "Kadın", "Diğer"]
    let bloodTypes = ["A+", "A-", "B+", "B-", "AB+", "AB-", "0+", "0-"]
    
    private var primaryColor: Color { Color(hex: "06B6D4") }
    
    var body: some View {
        ZStack {
            NKColors.bgPrimary.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 48))
                            .foregroundColor(primaryColor)
                        
                        Text("Sağlık ve Fiziksel Bilgiler")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(NKColors.textPrimary)
                        
                        Text("Size daha iyi hizmet verebilmemiz için fiziksel özelliklerinizi güncel tutun.")
                            .font(.system(size: 15))
                            .foregroundColor(NKColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 24)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // Birth Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Doğum Tarihi")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(NKColors.textSecondary)
                            
                            DatePicker("", selection: $birthDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(NKColors.bgSecondary)
                                .cornerRadius(12)
                        }
                        
                        // Gender
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Cinsiyet")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(NKColors.textSecondary)
                            
                            Picker("Cinsiyet", selection: $gender) {
                                ForEach(genders, id: \.self) {
                                    Text($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(NKColors.bgSecondary)
                            .cornerRadius(12)
                        }
                        
                        // Height & Weight
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Boy (cm)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(NKColors.textSecondary)
                                
                                TextField("175", text: $heightCm)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(NKColors.bgSecondary)
                                    .cornerRadius(12)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Kilo (kg)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(NKColors.textSecondary)
                                
                                TextField("70.5", text: $weightKg)
                                    .keyboardType(.decimalPad)
                                    .padding()
                                    .background(NKColors.bgSecondary)
                                    .cornerRadius(12)
                            }
                        }
                        
                        // Blood Type
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Kan Grubu")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(NKColors.textSecondary)
                            
                            Picker("Kan Grubu", selection: $bloodType) {
                                ForEach(bloodTypes, id: \.self) {
                                    Text($0)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(NKColors.bgSecondary)
                            .cornerRadius(12)
                        }
                        
                        // Diseases Selection
                        if !allDiseases.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Sahip Olunan Hastalıklar")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(NKColors.textSecondary)
                                
                                VStack(spacing: 12) {
                                    ForEach(allDiseases) { disease in
                                        Button(action: {
                                            if selectedDiseaseIds.contains(disease.id) {
                                                selectedDiseaseIds.remove(disease.id)
                                            } else {
                                                selectedDiseaseIds.insert(disease.id)
                                            }
                                        }) {
                                            HStack {
                                                Text(disease.name)
                                                    .foregroundColor(NKColors.textPrimary)
                                                Spacer()
                                                if selectedDiseaseIds.contains(disease.id) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(primaryColor)
                                                } else {
                                                    Image(systemName: "circle")
                                                        .foregroundColor(NKColors.textTertiary)
                                                }
                                            }
                                            .padding()
                                            .background(NKColors.bgSecondary)
                                            .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 40)
                    
                    // Save Button
                    Button(action: saveProfile) {
                        HStack {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            Text("Kaydet")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(isSaving ? primaryColor.opacity(0.7) : primaryColor)
                        )
                        .shadow(color: primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isSaving)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationTitle("Sağlık Bilgileri")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentProfile()
            Task {
                try? await loadDiseases()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Bilgi"), message: Text(alertMessage), dismissButton: .default(Text("Tamam")))
        }
    }
    
    private func loadDiseases() async throws {
        let diseases = try await authService.fetchDiseases()
        await MainActor.run {
            self.allDiseases = diseases
        }
    }
    
    private func loadCurrentProfile() {
        if let profile = authService.currentProfile {
            if let dateString = profile.birthDate {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                if let date = formatter.date(from: String(dateString.prefix(10))) {
                    self.birthDate = date
                }
            }
            if let g = profile.gender { self.gender = g }
            if let h = profile.heightCm { self.heightCm = String(format: "%.0f", h) }
            if let w = profile.weightKg { self.weightKg = String(format: "%.1f", w) }
            if let bt = profile.bloodType { self.bloodType = bt }
            if let dIds = profile.diseaseIds { self.selectedDiseaseIds = Set(dIds) }
        }
    }
    
    private func saveProfile() {
        isSaving = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: birthDate)
        
        let h = Double(heightCm.replacingOccurrences(of: ",", with: "."))
        let w = Double(weightKg.replacingOccurrences(of: ",", with: "."))
        
        Task {
            do {
                try await authService.updateProfile(
                    birthDate: dateString,
                    gender: gender,
                    heightCm: h,
                    weightKg: w,
                    bloodType: bloodType,
                    diseaseIds: Array(selectedDiseaseIds)
                )
                
                await MainActor.run {
                    isSaving = false
                    alertMessage = "Bilgileriniz başarıyla güncellendi."
                    showAlert = true
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    alertMessage = "Güncelleme sırasında bir hata oluştu: \(error.localizedDescription)"
                    showAlert = true
                }
            }
        }
    }
}
