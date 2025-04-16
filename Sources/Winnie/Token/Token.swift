public enum Token: CustomStringConvertible, CustomDebugStringConvertible, Equatable {
  case equals, colon, plus, minus, bang, newline, eof
  case section(String)
  case string(String)
  case comment(String)

  public var description: String {
    switch self {
    // Reserved for future use
    case .plus: "+"
    case .bang: "!"
    // Single tokens
    case .equals: "="
    case .colon: ":"
    case .minus: "-"
    case .newline: "\n"
    case .eof: "EOF"
    // Value tokens
    case let .section(value): "[\(value)]"
    case let .string(value): value
    case let .comment(value): value
    }
  }

  public var debugDescription: String {
    switch self {
    case .plus: "plus::<+>"
    case .bang: "bang::<!>"
    case .equals: "equals::<=>"
    case .colon: "colon::,<:>"
    case .minus: "minus::<->"
    case .newline: "newline::<\n>"
    case .eof: "eof::<EOF>"
    case let .section(value): "section::<\(value)]"
    case let .string(value): "string::<\(value)>"
    case let .comment(value): "comment::<\(value)>"
    }
  }
}
