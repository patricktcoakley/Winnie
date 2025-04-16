public protocol INIValueConvertible {
  func into() -> INIValue
  static func from(_ value: INIValue) throws(ConfigParserError) -> Self
}

extension String: INIValueConvertible {
  public func into() -> INIValue { .string(self) }

  public static func from(_ value: INIValue) throws(ConfigParserError) -> String {
    switch value {
    case let .string(string): string
    default: value.description
    }
  }
}

extension Bool: INIValueConvertible {
  public func into() -> INIValue { .bool(self) }

  public static func from(_ value: INIValue) throws(ConfigParserError) -> Bool {
    switch value {
    case let .bool(bool): bool
    case let .string(string):
      switch string.lowercased() {
      case "true", "yes", "1", "on": true
      case "false", "no", "0", "off": false
      default: throw ConfigParserError.valueError("Cannot convert to Bool: \(string)")
      }
    case let .double(t): t > 0.0
    case let .int(i): i > 0
    }
  }
}

extension Int: INIValueConvertible {
  public func into() -> INIValue { .int(self) }

  public static func from(_ value: INIValue) throws(ConfigParserError) -> Int {
    switch value {
    case let .int(int): return int
    case let .bool(bool): return !bool ? 0 : 1
    case let .double(double): return Int(double)
    case let .string(string):
      guard let result = Int(string) else {
        throw ConfigParserError.valueError("Cannot convert to Int: \(string)")
      }
      return result
    }
  }
}

extension Double: INIValueConvertible {
  public func into() -> INIValue { .double(self) }

  public static func from(_ value: INIValue) throws(ConfigParserError) -> Double {
    switch value {
    case let .double(double): return double
    case let .int(int): return Double(int)
    case let .bool(bool): return !bool ? 0.0 : 1.0
    case let .string(string):
      guard let result = Double(string) else {
        throw ConfigParserError.valueError("Cannot convert to Double: \(string)")
      }
      return result
    }
  }
}
