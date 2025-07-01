extension Int: INIValueConvertible {
  public func into() -> INIValue { .int(self) }

  public static func from(_ value: INIValue) throws(ConfigParserError) -> Int {
    switch value {
    case let .int(int): return int
    case let .bool(bool): return !bool ? 0 : 1
    case let .double(double):
      guard double.isFinite else {
        throw ConfigParserError.valueError("Cannot convert non-finite Double \(double) to Int")
      }
      guard double >= Double(Int.min), double <= Double(Int.max) else {
        throw ConfigParserError.valueError("Cannot convert Double \(double) to Int: out of Int range")
      }
      return Int(double)
    case let .string(string):
      guard let result = Int(string) else {
        throw ConfigParserError.valueError("Cannot convert to Int: \(string)")
      }
      return result
    }
  }
}
