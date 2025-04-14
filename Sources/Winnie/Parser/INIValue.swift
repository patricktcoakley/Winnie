public enum INIValue: CustomStringConvertible, INIValueConvertible {
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

  public var description: String {
    return switch self {
    case let .string(value): value
    case let .int(value): String(value)
    case let .double(value): String(value)
    case let .bool(value): value ? "True" : "False"
    }
  }

  public func into() -> INIValue { self }
  public static func from(_ value: INIValue) throws(ConfigParserError) -> Self { value }
}
