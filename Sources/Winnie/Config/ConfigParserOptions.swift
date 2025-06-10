public enum AssignmentCharacter: String {
  case equals = "="
  case colon = ":"
}

public struct ConfigParserOptions {
  public let defaultSection: String
  public let assignmentCharacter: AssignmentCharacter
  public let leadingSpaces: Int
  public let trailingSpaces: Int

  public init(
    defaultSection: String = "DEFAULT",
    assignmentCharacter: AssignmentCharacter = .equals,
    leadingSpaces: Int? = nil,
    trailingSpaces: Int? = nil
  ) {
    self.defaultSection = defaultSection
    self.assignmentCharacter = assignmentCharacter

    let defaultLeading = assignmentCharacter == .equals ? 1 : 0
    let defaultTrailing = 1

    let computedLeading = leadingSpaces ?? trailingSpaces ?? defaultLeading
    let computedTrailing = trailingSpaces ?? leadingSpaces ?? defaultTrailing

    self.leadingSpaces = computedLeading
    self.trailingSpaces = computedTrailing
  }
}
