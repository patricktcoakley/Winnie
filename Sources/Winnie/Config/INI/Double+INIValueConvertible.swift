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
