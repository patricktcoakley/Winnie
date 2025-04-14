public enum TokenizerError: Error, Equatable {
  case unterminatedString(line: Int)
  case syntax(line: Int, message: String)
}

public enum Token: CustomStringConvertible, Equatable {
  case leftBracket, rightBracket, equals, hash, colon, semicolon, eof
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
    case .eof: "EOF"
    }
  }
}

public class Tokenizer {
  let input: String
  var line = 1
  var currentIndex: String.Index
  var current: Character { input[currentIndex] }
  var peekIndex: String.Index { input.index(after: currentIndex) }
  var peek: Character? {
    let next = input.index(after: currentIndex)
    return next < input.endIndex ? input[next] : nil
  }

  var isSupportedCharacter: Bool {
    current.isLetter || current.isNumber || current == "_" || current == "-" || current == "." ||
      current == "+" || current == "!" || current == " "
  }

  init(_ input: String) {
    self.input = input
    currentIndex = self.input.startIndex
  }

  public func tokenize() throws(TokenizerError) -> [Token] {
    var tokens: [Token] = []
    while true {
      let token = try scan()
      tokens.append(token)
      if token == .eof { break }
    }
    return tokens
  }

  public func scan() throws(TokenizerError) -> Token {
    skipWhitespace()

    guard currentIndex < input.endIndex else { return .eof }

    switch current {
    case "[":
      advance()
      return .leftBracket
    case "]":
      advance()
      return .rightBracket
    case "=":
      advance()
      return .equals
    case ":":
      advance()
      return .colon
    case "\"":
      return try handleQuotedString()
    case "#", ";": return handleComment()
    default: return handleString()
    }
  }

  private func advance() {
    if current == "\n" { line += 1 }
    currentIndex = input.index(after: currentIndex)
  }

  private func skipWhitespace() {
    while currentIndex < input.endIndex, current.isWhitespace {
      advance()
    }
  }

  private func handleQuotedString() throws(TokenizerError) -> Token {
    var stringValue = ""

    advance()

    while currentIndex < input.endIndex {
      let char = current

      if char == "\"" { // End quote
        advance()
        return .string(stringValue)
      }

      if char == "\\" {
        advance()
        if currentIndex < input.endIndex {
          let escaped = current
          switch escaped {
          case "n": stringValue.append("\n")
          case "t": stringValue.append("\t")
          case "r": stringValue.append("\r")
          case "\"": stringValue.append("\"")
          case "\\": stringValue.append("\\")
          default: stringValue.append(escaped)
          }
          advance()
        }
        continue
      }

      stringValue.append(char)
      advance()
    }

    throw TokenizerError.unterminatedString(line: line)
  }

  private func handleString() -> Token {
    var stringValue = ""

    while currentIndex < input.endIndex {
      if !isSupportedCharacter {
        return .string(stringValue.trimmingCharacters(in: .whitespaces))
      }

      stringValue.append(current)
      advance()
    }

    return .string(stringValue)
  }

  private func handleComment() -> Token {
    var stringValue = String(current)
    advance()

    while currentIndex < input.endIndex && current != "\n" {
      stringValue.append(current)
      advance()
    }

    return .string(stringValue)
  }
}
