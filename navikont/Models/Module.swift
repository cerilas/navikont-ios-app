import Foundation

struct Module: Codable, Identifiable, Sendable {
    /// This is the module_version_id from the backend
    let id: UUID
    let moduleId: UUID?
    let title: String
    let subtitle: String?
    let moduleType: String
    let content: ModuleContent?
    let isRequired: Bool?

    /// Default isRequired to true if nil
    var required: Bool {
        isRequired ?? true
    }
}

/// Flexible content wrapper: can be a JSON object or a plain string
enum ModuleContent: Codable, Sendable {
    case text(String)
    case dictionary([String: AnyCodableValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        // Try dictionary first
        if let dict = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(dict)
            return
        }
        // Fall back to string
        if let text = try? container.decode(String.self) {
            self = .text(text)
            return
        }
        self = .text("")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let str):
            try container.encode(str)
        case .dictionary(let dict):
            try container.encode(dict)
        }
    }

    /// Returns the text content regardless of how it was stored
    var textValue: String {
        switch self {
        case .text(let str):
            return str
        case .dictionary(let dict):
            if let body = dict["body"]?.stringValue {
                return body
            }
            if let text = dict["text"]?.stringValue {
                return text
            }
            if let instructions = dict["instructions"]?.stringValue {
                return instructions
            }
            if let desc = dict["description"]?.stringValue {
                return desc
            }
            if let html = dict["html"]?.stringValue {
                return html
            }
            if let htmlContent = dict["htmlContent"]?.stringValue {
                return htmlContent
            }
            if let descriptionHtml = dict["descriptionHtml"]?.stringValue {
                return descriptionHtml
            }
            if let consentTextHtml = dict["consentTextHtml"]?.stringValue {
                return consentTextHtml
            }
            // Return JSON representation as fallback
            if let data = try? JSONEncoder().encode(dict),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return ""
        }
    }
    
    var videoUrl: String? {
        if case .dictionary(let dict) = self {
            return dict["videoUrl"]?.stringValue
        }
        return nil
    }
}

/// Type-erased Codable value for flexible JSON parsing
enum AnyCodableValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])
    case null

    var stringValue: String? {
        switch self {
        case .string(let v): return v
        case .int(let v): return String(v)
        case .double(let v): return String(v)
        case .bool(let v): return String(v)
        default: return nil
        }
    }

    var intValue: Int? {
        switch self {
        case .int(let v): return v
        case .double(let v): return Int(v)
        case .string(let v): return Int(v)
        default: return nil
        }
    }

    var doubleValue: Double? {
        switch self {
        case .double(let v): return v
        case .int(let v): return Double(v)
        case .string(let v): return Double(v)
        default: return nil
        }
    }

    var boolValue: Bool? {
        switch self {
        case .bool(let v): return v
        default: return nil
        }
    }

    var arrayValue: [AnyCodableValue]? {
        if case .array(let v) = self { return v }
        return nil
    }

    var dictionaryValue: [String: AnyCodableValue]? {
        if case .dictionary(let v) = self { return v }
        return nil
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
            return
        }
        if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Int.self) {
            self = .int(v)
        } else if let v = try? container.decode(Double.self) {
            self = .double(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else if let v = try? container.decode([AnyCodableValue].self) {
            self = .array(v)
        } else if let v = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(v)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .int(let v): try container.encode(v)
        case .double(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .dictionary(let v): try container.encode(v)
        case .null: try container.encodeNil()
        }
    }
}
