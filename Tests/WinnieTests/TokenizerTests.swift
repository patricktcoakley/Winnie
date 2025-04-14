import Testing
@testable import Winnie

struct TokenizerTests {
  @Test func testSimpleString() throws {
    let tokenizer = Tokenizer("\"Hello, world!\"")
    let token = try tokenizer.scan()
    #expect(token == .string("Hello, world!"))
  }

  @Test func testStringWithEscapedQuote() throws {
    let tokenizer = Tokenizer("\"Hello, \\\"world!\\\"\"")
    let token = try tokenizer.scan()
    #expect(token == .string("Hello, \"world!\""))
  }

  @Test func testStringWithEscapedBackslash() throws {
    let tokenizer = Tokenizer("\"Hello \\\\ world\"")
    let token = try tokenizer.scan()
    #expect(token == .string("Hello \\ world"))
  }

  @Test func testEmptyString() throws {
    let tokenizer = Tokenizer("\"\"")
    let token = try tokenizer.scan()
    #expect(token == .string(""))
  }

  @Test func testEmptyInput() throws {
    let tokenizer = Tokenizer("")
    let token = try tokenizer.scan()
    #expect(token == .eof)
  }

  @Test func testUnterminatedString() throws {
    let tokenizer = Tokenizer("\"Unfinished")
    #expect(throws: TokenizerError.unterminatedString(line: 1)) {
      try tokenizer.scan()
    }
  }

  @Test func testSimpleKeyValue() throws {
    let tokenizer = Tokenizer("name = John")
    let key = try tokenizer.scan()
    let equals = try tokenizer.scan()
    let value = try tokenizer.scan()

    #expect(key == .string("name"))
    #expect(equals == .equals)
    #expect(value == .string("John"))
  }

  @Test func testCommentWithHash() throws {
    let tokenizer = Tokenizer("# this is a comment")
    let token = try tokenizer.scan()
    #expect(token == .string("# this is a comment"))
  }

  @Test func testCommentWithSemicolon() throws {
    let tokenizer = Tokenizer("; this is a comment")
    let token = try tokenizer.scan()
    #expect(token == .string("; this is a comment"))
  }

  @Test func testSectionHeader() throws {
    let tokenizer = Tokenizer("[section]")
    let left = try tokenizer.scan()
    let name = try tokenizer.scan()
    let right = try tokenizer.scan()

    #expect(left == .leftBracket)
    #expect(name == .string("section"))
    #expect(right == .rightBracket)
  }

  @Test func testKeyWithSpecialCharacters() throws {
    let tokenizer = Tokenizer("key-with_special.chars = value")
    let key = try tokenizer.scan()
    #expect(key == .string("key-with_special.chars"))
  }

  @Test func testMissingValueAfterEquals() throws {
    let input = "key = "
    let tokenizer = Tokenizer(input)

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

    let tokenizer = Tokenizer(input)
    let tokens = try tokenizer.tokenize()

    let expected: [Token] = [
      .leftBracket, .string("section1"), .rightBracket,
      .leftBracket, .string("section2"), .rightBracket,
      .eof
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
      .string("# Global settings"),

      .leftBracket, .string("general"), .rightBracket,
      .string("app_name"), .equals, .string("TestApp"),
      .string("version"), .equals, .string("1.0.0"),
      .string("debug"), .equals, .string("true"),

      .string("; User config"),

      .leftBracket, .string("user"), .rightBracket,
      .string("name"), .equals, .string("Jane Doe"),
      .string("email"), .equals, .string("jane@example.com"),

      .leftBracket, .string("network"), .rightBracket,
      .string("host"), .equals, .string("localhost"),
      .string("port"), .equals, .string("8080"),

      .eof
    ]

    let tokenizer = Tokenizer(input)
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
      .leftBracket, .string("URL"), .rightBracket,
      .string("Protocol"), .equals, .string("deusex"),
      .string("Host"), .equals, .string(""),
      .eof
    ]

    let tokenizer = Tokenizer(contents)
    let tokens = try tokenizer.tokenize()
    #expect(tokens == expected)
  }
}
