public enum ConfigParserError: Error, Equatable {
  case sectionNotFound(String)
  case optionNotFound(String)
  case valueError(String)
}
