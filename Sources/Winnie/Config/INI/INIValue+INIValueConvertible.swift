extension INIValue: INIValueConvertible {
  public func into() -> INIValue { self }
  public static func from(_ value: INIValue) throws(ConfigParserError) -> Self { value }
}
