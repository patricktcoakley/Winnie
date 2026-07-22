extension Int: INIValueConvertible {
  public func into() -> INIValue { .int(self) }

  public static func from(_ value: INIValue) throws(ConfigParserError) -> Int {
    switch value {
    case .int(let int): return int
    case .bool(let bool): return !bool ? 0 : 1
    case .double(let double):
      guard double.isFinite else {
        throw ConfigParserError.valueError("Cannot convert non-finite Double \(double) to Int")
      }
      guard double >= Double(Int.min), double <= Double(Int.max) else {
        throw ConfigParserError.valueError(
          "Cannot convert Double \(double) to Int: out of Int range")
      }
      return Int(double)
    case .string(let string):
      guard let result = Int(string) else {
        throw ConfigParserError.valueError("Cannot convert to Int: \(string)")
      }
      return result
    }
  }
}
