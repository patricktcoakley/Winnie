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
    case .section(let value): "section::<\(value)]"
    case .string(let value): "string::<\(value)>"
    case .comment(let value): "comment::<\(value)>"
    }
  }
}
