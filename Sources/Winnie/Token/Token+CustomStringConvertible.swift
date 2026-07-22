extension Token: CustomStringConvertible {
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
    case .section(let value): "[\(value)]"
    case .string(let value): value
    case .comment(let value): value
    }
  }
}
