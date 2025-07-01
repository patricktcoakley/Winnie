enum TokenizerError: Error, Equatable {
  case unterminatedSection(line: Int)
  case unterminatedString(line: Int)
  case syntax(line: Int, message: String)
}
