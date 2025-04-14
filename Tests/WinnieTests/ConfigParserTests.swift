import Testing
@testable import Winnie

struct ConfigParserTests {
  @Test func testInitialization() {
    let parser = ConfigParser()
    #expect(parser.sections.count == 1)
    #expect(parser.hasSection("DEFAULT"))
  }

  @Test func testAddSection() throws {
    let parser = ConfigParser()
    try parser.addSection("test")
    #expect(parser.hasSection("test"))
    #expect(parser.sections.count == 2)
  }

  @Test func testAddSectionFailsForDefault() {
    let parser = ConfigParser()
    #expect(throws: ConfigParserError.valueError("Cannot add default section.")) {
      try parser.addSection("DEFAULT")
    }
  }

  @Test func testAddSectionFailsForExisting() throws {
    let parser = ConfigParser()
    try parser.addSection("test")
    #expect(throws: ConfigParserError.valueError("Section test already exists.")) {
      try parser.addSection("test")
    }
  }

  @Test func testSetAndGetString() throws {
    let parser = ConfigParser()
    parser.set(section: "user", option: "name", value: "John")

    let name: String = try parser.get(section: "user", option: "name")
    #expect(name == "John")
  }

  @Test func testSetAndGetInt() throws {
    let parser = ConfigParser()
    parser.set(section: "user", option: "age", value: 30)

    let age: Int = try parser.get(section: "user", option: "age")
    #expect(age == 30)
  }

  @Test func testSetAndGetBool() throws {
    let parser = ConfigParser()
    parser.set(section: "features", option: "enabled", value: true)

    let enabled: Bool = try parser.get(section: "features", option: "enabled")
    #expect(enabled)
  }

  @Test func testSetAndGetDouble() throws {
    let parser = ConfigParser()
    parser.set(section: "settings", option: "ratio", value: 3.14)

    let ratio: Double = try parser.get(section: "settings", option: "ratio")
    #expect(ratio == 3.14)
  }

  @Test func testTypeConversion() throws {
    let parser = ConfigParser()
    parser.set(section: "test", option: "value", value: "42")

    let intValue: Int = try parser.get(section: "test", option: "value")
    #expect(intValue == 42)

    let doubleValue: Double = try parser.get(section: "test", option: "value")
    #expect(doubleValue == 42.0)
  }

  @Test func testBoolConversions() throws {
    let parser = ConfigParser()
    parser.set(section: "test", option: "yes", value: "yes")
    parser.set(section: "test", option: "no", value: "no")
    parser.set(section: "test", option: "one", value: 1)
    parser.set(section: "test", option: "zero", value: 0)

    let yes: Bool = try parser.get(section: "test", option: "yes")
    let no: Bool = try parser.get(section: "test", option: "no")
    let one: Bool = try parser.get(section: "test", option: "one")
    let zero: Bool = try parser.get(section: "test", option: "zero")

    #expect(yes)
    #expect(!no)
    #expect(one)
    #expect(!zero)
  }

  @Test func testSectionNotFound() {
    let parser = ConfigParser()
    #expect(throws: ConfigParserError.sectionNotFound("nonexistent")) {
      let _: String = try parser.get(section: "nonexistent", option: "option")
    }
  }

  @Test func testOptionNotFound() throws {
    let parser = ConfigParser()
    try parser.addSection("test")
    #expect(throws: ConfigParserError.optionNotFound("nonexistent")) {
      let _: String = try parser.get(section: "test", option: "nonexistent")
    }
  }

  @Test func testDefaultSection() throws {
    let parser = ConfigParser()
    parser.set(option: "version", value: "1.0")

    let version: String = try parser.get(option: "version")
    #expect(version == "1.0")
  }

  @Test func testInvalidTypeConversion() {
    let parser = ConfigParser()
    parser.set(section: "test", option: "text", value: "hello")

    #expect(throws: ConfigParserError.valueError("Cannot convert to Int: hello")) {
      let _: Int = try parser.get(section: "test", option: "text")
    }
  }

  @Test func readExample() throws {
    let contents = """
    [URL]
    Protocol=deusex
    ProtocolDescription=Deus Ex Protocol
    Name=Player
    Map=Index.dx
    LocalMap=DX.dx
    Host=
    Portal=
    MapExt=dx 
    SaveExt=dxs
    Port=7790
    Class=DeusEx.JCDentonMale       

    [Engine.GameInfo]
    bLowGore=False
    """

    let configParser = ConfigParser()
    try configParser.read(contents)
    #expect(configParser.hasSection("URL"))
    #expect(try configParser.get(section: "URL", option: "Host") == "")
    #expect(try configParser.get(section: "URL", option: "Portal") == "")
    #expect(try configParser.get(section: "URL", option: "Name") == "Player")
    #expect(try configParser.get(section: "URL", option: "Port") == 7790)
    #expect(try configParser.get(section: "URL", option: "ProtocolDescription") == "Deus Ex Protocol")
    #expect(try configParser.get(section: "URL", option: "Class") == "DeusEx.JCDentonMale")
    #expect(try configParser.get(section: "Engine.GameInfo", option: "bLowGore") == false)
  }

  @Test func writeExample() throws {
    let configParser = ConfigParser()

    try configParser.addSection("URL")
    configParser.set(section: "URL", option: "Protocol", value: "deusex")
    configParser.set(section: "URL", option: "Name", value: "Player")
    configParser.set(section: "URL", option: "Port", value: 7790)

    try configParser.addSection("Engine.GameInfo")
    configParser.set(section: "Engine.GameInfo", option: "bLowGore", value: false)

    let result = configParser.write(leadingSpaces: false)

    let expected = """
    [URL]
    Protocol=deusex
    Name=Player
    Port=7790

    [Engine.GameInfo]
    bLowGore=False
    """

    #expect(result == expected)
  }

  @Test func testMixedAssignmentStyles() throws {
    let input = """
    [Settings]
    useColor=true
    fontSize: 12
    theme = "dark"
    """

    let parser = ConfigParser()
    try parser.read(input)

    let useColor: Bool = try parser.get(section: "Settings", option: "useColor")
    let fontSize: Int = try parser.get(section: "Settings", option: "fontSize")
    let theme: String = try parser.get(section: "Settings", option: "theme")

    #expect(useColor == true)
    #expect(fontSize == 12)
    #expect(theme == "dark")
  }

  @Test func testMultilineValues() throws {
    let parser = ConfigParser()
    try parser.read("""
    [Content]
    description = "This is a\\nmultiline\\nvalue"
    sql = "SELECT * FROM users\\nWHERE active = 1;"
    """)

    let description: String = try parser.get(section: "Content", option: "description")
    #expect(description == "This is a\nmultiline\nvalue")
  }

  @Test func testSectionOrderPreservation() throws {
    let parser = ConfigParser()

    try parser.addSection("Third")
    try parser.addSection("First")
    try parser.addSection("Second")

    let sections = parser.sections.filter { $0 != "DEFAULT" }
    #expect(sections == ["Third", "First", "Second"])
  }

  @Test func testOptionOrderPreservation() throws {
    let parser = ConfigParser()

    try parser.addSection("Test")
    parser.set(section: "Test", option: "z", value: 1)
    parser.set(section: "Test", option: "a", value: 2)
    parser.set(section: "Test", option: "m", value: 3)

    let section = parser.config["Test"]!
    let keys = Array(section.keys)
    #expect(keys == ["z", "a", "m"])
  }

  @Test func testEmptySections() throws {
    let input = """
    [EmptySection]

    [Section]
    emptyValue=
    """

    let parser = ConfigParser()
    try parser.read(input)

    #expect(parser.hasSection("EmptySection"))
    let emptyValue: String = try parser.get(section: "Section", option: "emptyValue")
    #expect(emptyValue == "")
  }

  @Test func testValueConversions() throws {
    let parser = ConfigParser()

    parser.set(section: "Test", option: "boolYes", value: "yes")
    parser.set(section: "Test", option: "boolOn", value: "on")
    parser.set(section: "Test", option: "boolFalse", value: false)
    parser.set(section: "Test", option: "intAsString", value: "42")
    parser.set(section: "Test", option: "doubleNegative", value: -3.14)

    let boolYes: Bool = try parser.get(section: "Test", option: "boolYes")
    let boolOn: Bool = try parser.get(section: "Test", option: "boolOn")
    let boolFalse: Bool = try parser.get(section: "Test", option: "boolFalse")
    let intFromString: Int = try parser.get(section: "Test", option: "intAsString")
    let doubleNeg: Double = try parser.get(section: "Test", option: "doubleNegative")

    #expect(boolYes == true)
    #expect(boolOn == true)
    #expect(boolFalse == false)
    #expect(intFromString == 42)
    #expect(doubleNeg == -3.14)
  }

  @Test func testCommentHandling() throws {
    let input = """
    [Section]
    # This is a comment
    key1=value1 ; This is an inline comment
    ; Another comment
    key2=value2
    """

    let parser = ConfigParser()
    try parser.read(input)

    let key1: String = try parser.get(section: "Section", option: "key1")
    let key2: String = try parser.get(section: "Section", option: "key2")

    #expect(key1 == "value1")
    #expect(key2 == "value2")
  }

  @Test func testRoundtrip() throws {
    let original = """
    [Section1]
    key1=value1
    key2=True

    [Section2]
    key3=42
    """

    let parser1 = ConfigParser()
    try parser1.read(original)

    let written = parser1.write(leadingSpaces: false)

    let parser2 = ConfigParser()
    try parser2.read(written)

    let key1: String = try parser2.get(section: "Section1", option: "key1")
    let key2: Bool = try parser2.get(section: "Section1", option: "key2")
    let key3: Int = try parser2.get(section: "Section2", option: "key3")

    #expect(key1 == "value1")
    #expect(key2 == true)
    #expect(key3 == 42)
  }

  @Test func endToEnd() throws {
    let expected = """
    [DEFAULT]
    ServerAliveInterval = 45
    Compression = yes
    CompressionLevel = 9
    ForwardX11 = yes

    [forge.example]
    User = hg

    [topsecret.server.example]
    Port = 50022
    ForwardX11 = no
    """

    let config = ConfigParser()
    config.set(option: "ServerAliveInterval", value: 45)
    config.set(option: "Compression", value: "yes")
    config.set(option: "CompressionLevel", value: 9)
    config.set(option: "ForwardX11", value: "yes")

    try config.addSection("forge.example")
    config.set(section: "forge.example", option: "User", value: "hg")

    try config.addSection("topsecret.server.example")
    config.set(section: "topsecret.server.example", option: "Port", value: 50022)
    config.set(section: "topsecret.server.example", option: "ForwardX11", value: "no")

    #expect(expected == config.write())
    let config2 = ConfigParser()
    try config2.read(expected)
    #expect(config2.write() == config.write())

    let expectedSections = ["DEFAULT", "forge.example", "topsecret.server.example"]
    #expect(expectedSections == config.sections)

    #expect(config.hasSection("forge.example"))
    #expect(!config.hasSection("python.org"))
    #expect(try config.get(section: "forge.example", option: "User") == "hg")
    #expect(try config.get(option: "Compression") == "yes")

    #expect(try config.get(section: "topsecret.server.example", option: "ForwardX11") == "no")
    #expect(try config.get(section: "topsecret.server.example", option: "Port") == 50022)
  }
}
