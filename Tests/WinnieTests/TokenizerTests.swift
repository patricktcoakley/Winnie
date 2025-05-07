import Testing
@testable import Winnie

struct TokenizerTests {
  @Test func testSimpleString() throws {
    var tokenizer = Tokenizer("\"Hello, world!\"")
    let token = try tokenizer.scan()
    #expect(token == .string("Hello, world!"))
  }

  @Test func testStringWithEscapedQuote() throws {
    var tokenizer = Tokenizer("\"Hello, \\\"world!\\\"\"")
    let token = try tokenizer.scan()
    #expect(token == .string("Hello, \"world!\""))
  }

  @Test func testStringWithEscapedBackslash() throws {
    var tokenizer = Tokenizer("\"Hello \\\\ world\"")
    let token = try tokenizer.scan()
    #expect(token == .string("Hello \\ world"))
  }

  @Test func testEmptyString() throws {
    var tokenizer = Tokenizer("\"\"")
    let token = try tokenizer.scan()
    #expect(token == .string(""))
  }

  @Test func testEmptyInput() throws {
    var tokenizer = Tokenizer("")
    let token = try tokenizer.scan()
    #expect(token == .eof)
  }

  @Test func testUnterminatedString() throws {
    var tokenizer = Tokenizer("\"Unfinished")
    #expect(throws: TokenizerError.unterminatedString(line: 1)) {
      try tokenizer.scan()
    }
  }

  @Test func testUnterminatedSection() throws {
    var tokenizer = Tokenizer("[section")
    #expect(throws: TokenizerError.unterminatedSection(line: 1)) {
      _ = try tokenizer.tokenize() // Or scan() depending on how deep you test
    }
  }

  @Test func testUnterminatedStringMultiLine() throws {
    let input = """
    key = value
    key2 = "Unfinished
    """
    var tokenizer = Tokenizer(input)
    #expect(throws: TokenizerError.unterminatedString(line: 2)) {
      _ = try tokenizer.tokenize()
    }
  }

  @Test func testUnterminatedSectionMultiLine() throws {
    let input = """
    key = value
    [section
    """
    var tokenizer = Tokenizer(input)
    #expect(throws: TokenizerError.unterminatedSection(line: 2)) {
      _ = try tokenizer.tokenize()
    }
  }

  @Test func testSimpleKeyValue() throws {
    var tokenizer = Tokenizer("name = John")
    let key = try tokenizer.scan()
    let equals = try tokenizer.scan()
    let value = try tokenizer.scan()

    #expect(key == .string("name"))
    #expect(equals == .equals)
    #expect(value == .string("John"))
  }

  @Test func testCommentWithHash() throws {
    var tokenizer = Tokenizer("# this is a comment")
    let token = try tokenizer.scan()

    #expect(token == .comment("# this is a comment"))
  }

  @Test func testCommentWithSemicolon() throws {
    var tokenizer = Tokenizer("; this is a comment")
    let token = try tokenizer.scan()

    #expect(token == .comment("; this is a comment"))
  }

  @Test func testInlineComments() throws {
    let input = """
    key1=value1;comment1
    key2 = value2 # comment2
    """
    var tokenizer = Tokenizer(input)
    let tokens = try tokenizer.tokenize()
    let expected: [Token] = [
      .string("key1"), .equals, .string("value1"), .comment(";comment1"), .newline,
      .string("key2"), .equals, .string("value2"), .comment("# comment2"),
      .eof,
    ]
    #expect(tokens == expected)
  }

  @Test func testSectionHeader() throws {
    var tokenizer = Tokenizer("[section]")
    let section = try tokenizer.scan()

    #expect(section == .section("section"))
  }

  @Test func testKeyWithSpecialCharacters() throws {
    var tokenizer = Tokenizer(#"Paths=..\System\*.u"#)
    let tokens = try tokenizer.tokenize()

    let expected: [Token] = [
      .string("Paths"), .equals, .string("..\\System\\*.u"), .eof,
    ]

    #expect(tokens == expected)
  }

  @Test func testMissingValueAfterEquals() throws {
    let input = "key = "
    var tokenizer = Tokenizer(input)

    let key = try tokenizer.scan()
    let equals = try tokenizer.scan()
    let value = try tokenizer.scan()

    #expect(key == .string("key"))
    #expect(equals == .equals)
    #expect(value == .eof)
  }

  @Test func testConsecutiveSections() throws {
    let input = """
    [section1]
    [section2]
    """

    var tokenizer = Tokenizer(input)
    let tokens = try tokenizer.tokenize()

    let expected: [Token] = [
      .section("section1"),
      .newline,
      .section("section2"),
      .eof,
    ]

    #expect(tokens == expected)
  }

  @Test func testSections() throws {
    let input = #"""
    # Global settings
    [general]
    app_name = "TestApp"
    version = "1.0.0"
    debug = true

    ; User config
    [user]
    name = "Jane Doe"
    email = "jane@example.com"

    [network]
    host = "localhost"
    port = "8080"
    """#

    let expected: [Token] = [
      .comment("# Global settings"), .newline,
      .section("general"), .newline,
      .string("app_name"), .equals, .string("TestApp"), .newline,
      .string("version"), .equals, .string("1.0.0"), .newline,
      .string("debug"), .equals, .string("true"), .newline,
      .newline,
      .comment("; User config"), .newline,
      .section("user"), .newline,
      .string("name"), .equals, .string("Jane Doe"), .newline,
      .string("email"), .equals, .string("jane@example.com"), .newline,
      .newline,
      .section("network"), .newline,
      .string("host"), .equals, .string("localhost"), .newline,
      .string("port"), .equals, .string("8080"),
      .eof,
    ]

    var tokenizer = Tokenizer(input)
    let tokens = try tokenizer.tokenize()

    #expect(tokens == expected)
  }

  @Test func testEmptyOption() throws {
    let contents = """
    [URL]
    Protocol=deusex
    Host=
    """

    let expected: [Token] = [
      .section("URL"), .newline,
      .string("Protocol"), .equals, .string("deusex"), .newline,
      .string("Host"), .equals,
      .eof,
    ]

    var tokenizer = Tokenizer(contents)
    let tokens = try tokenizer.tokenize()
    #expect(tokens == expected)
  }

  @Test func testNewlineCharacters() throws {
    let input = """
    key1 = value1

    key2 = value2
    """

    var tokenizer = Tokenizer(input)
    let tokens = try tokenizer.tokenize()

    let expected: [Token] = [
      .string("key1"), .equals, .string("value1"),
      .newline,
      .newline,
      .string("key2"), .equals, .string("value2"),
      .eof,
    ]

    #expect(tokens == expected)
  }

  @Test func testMixedContent() throws {
    let input = """
    [section1]
    key1 = value1

    # Comment
    [section2]
    key2:value2
    """

    var tokenizer = Tokenizer(input)
    let tokens = try tokenizer.tokenize()

    let expected: [Token] = [
      .section("section1"), .newline,
      .string("key1"), .equals, .string("value1"), .newline,
      .newline,
      .comment("# Comment"), .newline,
      .section("section2"), .newline,
      .string("key2"), .colon, .string("value2"),
      .eof,
    ]

    #expect(tokens == expected)
  }
}
