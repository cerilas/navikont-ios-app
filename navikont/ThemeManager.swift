import SwiftUI
import Combine

// MARK: - Theme Mode

enum ThemeMode: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return AppStrings.t("Otomatik")
        case .light: return AppStrings.t("Aydınlık")
        case .dark: return AppStrings.t("Karanlık")
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentMode: ThemeMode {
        didSet {
            UserDefaults.standard.set(currentMode.rawValue, forKey: "appThemeMode")
        }
    }
    
    init() {
        let saved = UserDefaults.standard.string(forKey: "appThemeMode") ?? "dark"
        self.currentMode = ThemeMode(rawValue: saved) ?? .dark
    }
    
    func cycleTheme() {
        switch currentMode {
        case .dark: currentMode = .light
        case .light: currentMode = .system
        case .system: currentMode = .dark
        }
    }
}
