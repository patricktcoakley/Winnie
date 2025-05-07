extension Token: CustomDebugStringConvertible {
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
