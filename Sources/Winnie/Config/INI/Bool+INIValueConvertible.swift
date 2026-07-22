extension Bool: INIValueConvertible {
  public func into() -> INIValue { .bool(self) }

  public static func from(_ value: INIValue) throws(ConfigParserError) -> Bool {
    switch value {
    case .bool(let bool): bool
    case .string(let string):
      switch string.lowercased() {
      case "true", "yes", "1", "on": true
      case "false", "no", "0", "off": false
      default: throw ConfigParserError.valueError("Cannot convert to Bool: \(string)")
      }
    case .double(let t): t > 0.0
    case .int(let i): i > 0
    }
  }
}
