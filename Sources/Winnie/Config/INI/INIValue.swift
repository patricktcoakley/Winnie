public enum INIValue: Equatable {
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
}
