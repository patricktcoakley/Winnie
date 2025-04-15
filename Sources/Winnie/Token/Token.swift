public enum Token: CustomStringConvertible, Equatable {
  case leftBracket, rightBracket, equals, colon, plus, minus, bang, newline, eof
  case string(String)
  case comment(String)

  public var description: String {
    return switch self {
    // Reserved for future use
    case .plus: "+"
    case .bang: "!"
    // Single tokens
    case .equals: "="
    case .leftBracket: "["
    case .rightBracket: "]"
    case .colon: ":"
    case .minus: "-"
    case .newline: "\n"
    case .eof: "EOF"
    // Value tokens
    case let .string(value): value
    case let .comment(value): value
    }
  }
}
