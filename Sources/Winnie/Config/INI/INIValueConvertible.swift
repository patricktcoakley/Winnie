public protocol INIValueConvertible {
  func into() -> INIValue
  static func from(_ value: INIValue) throws(ConfigParserError) -> Self
}
