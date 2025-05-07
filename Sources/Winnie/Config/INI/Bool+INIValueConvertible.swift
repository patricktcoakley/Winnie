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
