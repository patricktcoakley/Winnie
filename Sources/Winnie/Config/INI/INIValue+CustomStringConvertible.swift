extension INIValue: CustomStringConvertible {
  public var description: String {
    description(booleanFormat: ("True", "False"))
  }

  public func description(booleanFormat: (trueValue: String, falseValue: String)) -> String {
    switch self {
    case .string(let value): value
    case .int(let value): String(value)
    case .double(let value): String(value)
    case .bool(let value): value ? booleanFormat.trueValue : booleanFormat.falseValue
    }
  }
}
