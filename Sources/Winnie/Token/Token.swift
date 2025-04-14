public enum Token: CustomStringConvertible, Equatable {
  case leftBracket, rightBracket, equals, hash, colon, semicolon, newline, eof
  case string(String)

  public var description: String {
    return switch self {
    case .equals: "="
    case .leftBracket: "["
    case .rightBracket: "]"
    case .hash: "#"
    case .colon: ":"
    case .semicolon: ";"
    case let .string(value): value
    case .newline: "\n"
    case .eof: "EOF"
    }
  }
}
