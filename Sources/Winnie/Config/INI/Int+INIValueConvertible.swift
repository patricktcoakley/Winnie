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
