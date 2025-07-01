enum Token: Equatable {
  case equals, colon, plus, minus, bang, newline, eof
  case section(String)
  case string(String)
  case comment(String)
}
