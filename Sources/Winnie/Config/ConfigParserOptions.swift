/// The character used to separate option names from their values in INI files.
public enum AssignmentCharacter: String {
  /// Use equals sign (=) for assignment: `option = value`
  case equals = "="

  /// Use colon (:) for assignment: `option: value`
  case colon = ":"
}

/// Configuration options for customizing INI parsing and writing behavior.
///
/// Use `ConfigParserOptions` to control how INI files are parsed and generated,
/// including spacing, assignment characters, comment preservation, and boolean formatting.
///
/// ## Example
///
/// ```swift
/// let options = ConfigParserOptions(
///   assignmentCharacter: .colon,
///   leadingSpaces: 0,
///   trailingSpaces: 1,
///   preserveComments: true,
///   booleanFormat: ("yes", "no")
/// )
/// let parser = ConfigParser(options)
/// ```
public struct ConfigParserOptions {
  /// The name of the default section for options not explicitly placed in a section.
  public let defaultSection: String

  /// The character used to separate options from values (= or :).
  public let assignmentCharacter: AssignmentCharacter

  /// Number of spaces before the assignment character.
  public let leadingSpaces: Int

  /// Number of spaces after the assignment character.
  public let trailingSpaces: Int

  /// Whether to preserve comments when reading and writing INI files.
  public let preserveComments: Bool

  /// The string representations used for boolean true and false values.
  public let booleanFormat: (trueValue: String, falseValue: String)

  /// Creates configuration options with the specified settings.
  ///
  /// - Parameters:
  ///   - defaultSection: Name of the default section. Defaults to "DEFAULT".
  ///   - assignmentCharacter: Character for option-value assignment. Defaults to equals (=).
  ///   - leadingSpaces: Spaces before assignment character. Uses smart defaults based on assignment character.
  ///   - trailingSpaces: Spaces after assignment character. Uses smart defaults based on assignment character.
  ///   - preserveComments: Whether to preserve comments. Defaults to false.
  ///   - booleanFormat: String representations for boolean values. Defaults to ("True", "False").
  public init(
    defaultSection: String = "DEFAULT",
    assignmentCharacter: AssignmentCharacter = .equals,
    leadingSpaces: Int? = nil,
    trailingSpaces: Int? = nil,
    preserveComments: Bool = false,
    booleanFormat: (trueValue: String, falseValue: String) = ("True", "False")
  ) {
    self.defaultSection = defaultSection
    self.assignmentCharacter = assignmentCharacter

    let defaultLeading = assignmentCharacter == .equals ? 1 : 0
    let defaultTrailing = 1

    let computedLeading = leadingSpaces ?? trailingSpaces ?? defaultLeading
    let computedTrailing = trailingSpaces ?? leadingSpaces ?? defaultTrailing

    self.leadingSpaces = computedLeading
    self.trailingSpaces = computedTrailing
    self.preserveComments = preserveComments
    self.booleanFormat = booleanFormat
  }
}
