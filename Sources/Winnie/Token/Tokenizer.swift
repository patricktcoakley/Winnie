public final class Tokenizer {
  let input: String
  var line = 1
  var currentIndex: String.Index
  var current: Character { input[currentIndex] }

  var isSupportedCharacter: Bool {
    current.isLetter || current.isNumber || current == "_" || current == "-" || current == "."
      || current == " " || current == "*" || current == "/" || current == "\\"
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
      return try handleSection()
    case "=":
      advance()
      return .equals
    case ":":
      advance()
      return .colon
    case "+":
      advance()
      return .plus
    case "!":
      advance()
      return .bang
    case "\"":
      return try handleQuotedString()
    case "#", ";": return handleComment()
    case "\n":
      advance()
      return .newline
    default:
      guard isSupportedCharacter else {
        throw TokenizerError.syntax(line: line, message: "Unexpected character: \(current)")
      }
      return handleString()
    }
  }

  private func advance() {
    if current == "\n" { line += 1 }
    currentIndex = input.index(after: currentIndex)
  }

  private func skipWhitespace() {
    while currentIndex < input.endIndex, current.isWhitespace, !current.isNewline {
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
    let start = currentIndex

    while currentIndex < input.endIndex {
      if !isSupportedCharacter || current == "\n" {
        let value = input[start ..< currentIndex]
        return .string(String(value).trimmingCharacters(in: .whitespaces))
      }
      advance()
    }

    let value = input[start ..< currentIndex]
    return .string(String(value).trimmingCharacters(in: .whitespaces))
  }

  private func handleComment() -> Token {
    let start = currentIndex
    advance()

    while currentIndex < input.endIndex, current != "\n" {
      advance()
    }

    let value = input[start ..< currentIndex]

    return .comment(String(value).trimmingCharacters(in: .whitespaces))
  }

  private func handleSection() throws(TokenizerError) -> Token {
    advance()

    let start = currentIndex
    var didSectionEnd = false

    while currentIndex < input.endIndex, current != "\n" {
      if current == "]" {
        didSectionEnd = true
        break
      }

      if current == "\n" {
        throw TokenizerError.unterminatedSection(line: line)
      }

      advance()
    }

    if !didSectionEnd {
      throw TokenizerError.unterminatedSection(line: line)
    }

    let value = input[start ..< currentIndex]
    advance()

    return .section(String(value))
  }
}
