extension INIValue: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) { self = .string(value) }
}

extension INIValue: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) { self = .int(value) }
}

extension INIValue: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) { self = .bool(value) }
}

extension INIValue: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Double) { self = .double(value) }
}
