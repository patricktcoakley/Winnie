/// Errors that can occur during INI file parsing and configuration operations.
public enum ConfigParserError: Error, Equatable {
  /// Thrown when attempting to access a section that doesn't exist.
  case sectionNotFound(String)

  /// Thrown when attempting to access an option that doesn't exist in a section.
  case optionNotFound(String)

  /// Thrown when a value cannot be converted to the requested type.
  case valueError(String)
}
