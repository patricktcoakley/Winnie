extension Double: INIValueConvertible {
  public func into() -> INIValue { .double(self) }

  public static func from(_ value: INIValue) throws(ConfigParserError) -> Double {
    switch value {
    case .double(let double): return double
    case .int(let int): return Double(int)
    case .bool(let bool): return !bool ? 0.0 : 1.0
    case .string(let string):
      guard let result = Double(string) else {
        throw ConfigParserError.valueError("Cannot convert to Double: \(string)")
      }
      return result
    }
  }
}
