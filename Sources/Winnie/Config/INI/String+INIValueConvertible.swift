extension String: INIValueConvertible {
  public func into() -> INIValue { .string(self) }

  public static func from(_ value: INIValue) throws(ConfigParserError) -> String {
    switch value {
    case let .string(string): string
    default: value.description
    }
  }
}
