extension INIValue: CustomStringConvertible {
  public var description: String {
    description(booleanFormat: ("True", "False"))
  }

  public func description(booleanFormat: (trueValue: String, falseValue: String)) -> String {
    switch self {
    case let .string(value): value
    case let .int(value): String(value)
    case let .double(value): String(value)
    case let .bool(value): value ? booleanFormat.trueValue : booleanFormat.falseValue
    }
  }
}
