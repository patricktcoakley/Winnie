extension INIValue: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .string(value): value
    case let .int(value): String(value)
    case let .double(value): String(value)
    case let .bool(value): value ? "True" : "False"
    }
  }
}
