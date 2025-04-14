public enum TokenizerError: Error, Equatable {
  case unterminatedString(line: Int)
  case syntax(line: Int, message: String)
}
