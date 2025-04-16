public enum INIValue: CustomStringConvertible, Equatable, INIValueConvertible {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)

  public init(from string: String) {
    if let anInt = Int(string) {
      self = .int(anInt)
      return
    }

    if let aDouble = Double(string) {
      self = .double(aDouble)
      return
    }

    switch string.lowercased() {
    case "true", "yes", "1", "on":
      self = .bool(true)
      return
    case "false", "no", "0", "off":
      self = .bool(false)
      return
    default:
      self = .string(string)
    }
  }

  public var intValue: Int? { try? Int.from(self) }
  public var doubleValue: Double? { try? Double.from(self) }
  public var boolValue: Bool? { try? Bool.from(self) }
  public var stringValue: String? { try? String.from(self) }

  public var description: String {
    switch self {
    case let .string(value): value
    case let .int(value): String(value)
    case let .double(value): String(value)
    case let .bool(value): value ? "True" : "False"
    }
  }

  public func into() -> INIValue { self }
  public static func from(_ value: INIValue) throws(ConfigParserError) -> Self { value }
}

extension INIValue: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) { self = .string(value) }
}

extension INIValue: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) { self = .int(value) }
}

extension INIValue: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) { self = .string(value ? "True" : "False") }
}

extension INIValue: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Double) { self = .double(value) }
}
