import Foundation
import Testing

@testable import Winnie

struct ConfigParserTests {
  // MARK: - Initialization Tests

  @Test func testInitialization() {
    let parser = ConfigParser()
    #expect(parser.sectionNames.count == 1)
    #expect(parser.hasSection("DEFAULT"))
  }

  @Test func testInitFromFile() throws {
    let fileManager = FileManager.default
    let tempDirectory = fileManager.temporaryDirectory
    let tempFile = tempDirectory.appendingPathComponent("test_init.ini")

    let content = """
    [test]
    value = 42
    flag = true
    """

    try content.write(to: tempFile, atomically: true, encoding: .utf8)
    defer { try? fileManager.removeItem(at: tempFile) }

    let parser = try ConfigParser(file: tempFile.path, options: ConfigParserOptions())
    #expect(try parser.getString(section: "test", option: "value") == "42")
    #expect(try parser.getBool(section: "test", option: "flag") == true)
  }

  @Test func testInitFromString() throws {
    let content = """
    [test]
    value = hello world
    number = 99
    """

    let parser = try ConfigParser(input: content, options: ConfigParserOptions())
    #expect(try parser.getString(section: "test", option: "value") == "hello world")
    #expect(try parser.getInt(section: "test", option: "number") == 99)
  }

  @Test func testInitFileNotFound() {
    #expect(throws: Error.self) {
      try ConfigParser(file: "/nonexistent/path/file.ini", options: ConfigParserOptions())
    }
  }

  @Test func testInitStringWithMalformedContent() throws {
    let malformed = """
    [unclosed section
    key = value
    """

    #expect(throws: Error.self) {
      try ConfigParser(input: malformed, options: ConfigParserOptions())
    }
  }

  @Test func testAddSection() throws {
    let parser = ConfigParser()
    try parser.addSection("test")
    #expect(parser.hasSection("test"))
    #expect(parser.sectionNames.count == 2)
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

  // MARK: - Section Management Tests

  @Test func testRemoveSection() throws {
    let parser = ConfigParser()
    try parser.addSection("test")
    #expect(parser.hasSection("test"))

    try parser.removeSection("test")
    #expect(!parser.hasSection("test"))
  }

  @Test func testRemoveSectionNotFound() throws {
    let parser = ConfigParser()
    try parser.removeSection("nonexistent")
  }

  @Test func testRemoveDefaultSectionFails() {
    let parser = ConfigParser()
    #expect(throws: ConfigParserError.valueError("Cannot remove default section.")) {
      try parser.removeSection("DEFAULT")
    }
  }

  @Test func testItems() throws {
    let parser = ConfigParser()
    try parser.set(section: "DEFAULT", option: "key1", value: "value1")
    try parser.set(section: "DEFAULT", option: "key2", value: "value2")

    let items = try parser.items(section: "DEFAULT")
    #expect(items.count == 2)
  }

  @Test func testItemsSectionNotFound() {
    let parser = ConfigParser()
    #expect(throws: ConfigParserError.sectionNotFound("missing")) {
      _ = try parser.items(section: "missing")
    }
  }

  @Test func testGetBoolSimpleSuccess() throws {
    let parser = ConfigParser()
    try parser.read(#"""
    [test]
    flag = yes
    """#)
    #expect(try parser.getBool(section: "test", option: "flag") == true)
  }

  @Test func testGetStringSimpleSuccess() throws {
    let parser = ConfigParser()
    try parser.read(#"""
    [test]
    message = hello world
    """#)
    #expect(try parser.getString(section: "test", option: "message") == "hello world")
  }

  @Test func testGetIntSimpleSuccess() throws {
    let parser = ConfigParser()
    try parser.read(#"""
    [test]
    count = 99
    """#)
    #expect(try parser.getInt(section: "test", option: "count") == 99)
  }

  @Test func testGetDoubleSimpleSuccess() throws {
    let parser = ConfigParser()
    try parser.read(#"""
    [test]
    pi = 3.14159
    """#)
    #expect(try parser.getDouble(section: "test", option: "pi") == 3.14159)
  }

  @Test func testGetBoolSimpleTypeError() throws {
    let parser = ConfigParser()
    try parser.read(#"""
    [test]
    message = hello world
    """#)
    #expect(throws: ConfigParserError.valueError("Cannot convert to Bool: hello world")) {
      try parser.getBool(section: "test", option: "message")
    }
  }

  @Test func testGetIntSimpleTypeError() throws {
    let parser = ConfigParser()
    try parser.read(#"""
    [test]
    flag = yes
    """#)
    #expect(throws: ConfigParserError.valueError("Cannot convert to Int: yes")) {
      try parser.getInt(section: "test", option: "flag")
    }
  }

  @Test func testGetSimpleMissingOption() throws {
    let parser = ConfigParser()
    try parser.read(#"""
    [test]
    count = 99
    """#)
    #expect(throws: ConfigParserError.optionNotFound("missing")) {
      try parser.getInt(section: "test", option: "missing")
    }
  }

  @Test func testGetSimpleMissingSection() throws {
    let parser = ConfigParser()
    try parser.read(#"""
    [other_test]
    count = 99
    """#)
    #expect(throws: ConfigParserError.sectionNotFound("test")) {
      try parser.getInt(section: "test", option: "count")
    }
  }

  @Test func testGetIntAsString() throws {
    let parser = ConfigParser()
    try parser.read(#"""
    [data]
    value = 123
    """#)
    #expect(try parser.getString(section: "data", option: "value") == "123")
  }

  @Test func testGetBoolAsString() throws {
    let parser = ConfigParser()
    try parser.read(#"""
    [data]
    value = True
    """#)
    #expect(try parser.getString(section: "data", option: "value") == "True")
  }

  // MARK: - Default Value Tests

  @Test func testGetWithDefaultValue() throws {
    let parser = ConfigParser()
    try parser.addSection("test")
    parser["test", "existing"] = INIValue(from: "found")

    let existing: String = parser.get(section: "test", option: "existing", default: "default")
    #expect(existing == "found")

    let missing: String = parser.get(section: "test", option: "missing", default: "default")
    #expect(missing == "default")
  }

  @Test func testGetDefaultSectionWithDefault() {
    let parser = ConfigParser()
    parser["existing"] = INIValue(from: "found")

    let existing: String = parser.get(option: "existing", default: "default")
    #expect(existing == "found")

    let missing: String = parser.get(option: "missing", default: "default")
    #expect(missing == "default")
  }

  @Test func testSetAndGetString() throws {
    let parser = ConfigParser()

    try parser.addSection("user")
    try parser.set(section: "user", option: "name", value: "John")

    let name: String = try parser.get(section: "user", option: "name")
    #expect(name == "John")

    let age: Int = parser.get(section: "user", option: "age", default: 10)
    #expect(age == 10)
  }

  @Test func testSetAndGetInt() throws {
    let parser = ConfigParser()

    try parser.addSection("user")
    try parser.set(section: "user", option: "age", value: 30)

    let age: Int = try parser.get(section: "user", option: "age")
    #expect(age == 30)
  }

  @Test func testSetAndGetBool() throws {
    let parser = ConfigParser()

    try parser.addSection("features")
    try parser.set(section: "features", option: "enabled", value: true)

    let enabled: Bool = try parser.get(section: "features", option: "enabled")
    #expect(enabled)
  }

  @Test func testSetAndGetDouble() throws {
    let parser = ConfigParser()

    try parser.addSection("settings")
    try parser.set(section: "settings", option: "ratio", value: 3.14)

    let ratio: Double = try parser.get(section: "settings", option: "ratio")
    #expect(ratio == 3.14)
  }

  @Test func testTypeConversion() throws {
    let parser = ConfigParser()

    try parser.addSection("test")
    try parser.set(section: "test", option: "value", value: "42")

    let intValue: Int = try parser.get(section: "test", option: "value")
    #expect(intValue == 42)

    let doubleValue: Double = try parser.get(section: "test", option: "value")
    #expect(doubleValue == 42.0)
  }

  @Test func testBoolConversions() throws {
    let parser = ConfigParser()

    try parser.addSection("test")
    try parser.set(section: "test", option: "yes", value: "yes")
    try parser.set(section: "test", option: "no", value: "no")
    try parser.set(section: "test", option: "one", value: 1)
    try parser.set(section: "test", option: "zero", value: 0)

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
    try parser.set(option: "version", value: "1.0")

    let version: String = try parser.get(option: "version")
    #expect(version == "1.0")
  }

  @Test func testInvalidTypeConversion() throws {
    let parser = ConfigParser()

    try parser.addSection("test")
    try parser.set(section: "test", option: "text", value: "hello")

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

    let parser = ConfigParser()
    try parser.read(contents)
    #expect(parser.hasSection("URL"))
    #expect(try parser.get(section: "URL", option: "Host") == "")
    #expect(try parser.get(section: "URL", option: "Portal") == "")
    #expect(try parser.get(section: "URL", option: "Name") == "Player")
    #expect(try parser.get(section: "URL", option: "Port") == 7790)
    #expect(
      try parser.get(section: "URL", option: "ProtocolDescription") == "Deus Ex Protocol")
    #expect(try parser.get(section: "URL", option: "Class") == "DeusEx.JCDentonMale")
    #expect(try parser.get(section: "Engine.GameInfo", option: "bLowGore") == false)
  }

  @Test func writeExample() throws {
    let opts = ConfigParserOptions(leadingSpaces: 0, trailingSpaces: 0)
    let parser = ConfigParser(opts)

    try parser.addSection("URL")
    try parser.set(section: "URL", option: "Protocol", value: "deusex")
    try parser.set(section: "URL", option: "Name", value: "Player")
    try parser.set(section: "URL", option: "Port", value: 7790)

    try parser.addSection("Engine.GameInfo")
    try parser.set(section: "Engine.GameInfo", option: "bLowGore", value: false)

    let result = parser.write()

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
    try parser.read(
      """
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

    let sections = parser.sectionNames.filter { $0 != "DEFAULT" }
    #expect(sections == ["Third", "First", "Second"])
  }

  @Test func testOptionOrderPreservation() throws {
    let parser = ConfigParser()

    try parser.addSection("Test")
    try parser.set(section: "Test", option: "z", value: 1)
    try parser.set(section: "Test", option: "a", value: 2)
    try parser.set(section: "Test", option: "m", value: 3)

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

    try parser.addSection("Test")
    try parser.set(section: "Test", option: "boolYes", value: "yes")
    try parser.set(section: "Test", option: "boolOn", value: "on")
    try parser.set(section: "Test", option: "boolFalse", value: false)
    try parser.set(section: "Test", option: "intAsString", value: "42")
    try parser.set(section: "Test", option: "doubleNegative", value: -3.14)

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

  // MARK: - Type Conversion Edge Cases

  @Test func testIntegerOverflow() {
    let parser = ConfigParser()
    parser["test", "big"] = INIValue(from: "999999999999999999999") // Large number that won't parse as Int

    #expect(throws: ConfigParserError.self) {
      try parser.getInt(section: "test", option: "big")
    }
  }

  @Test func testDoubleSpecialValues() throws {
    let parser = ConfigParser()
    parser["test", "inf"] = INIValue(from: "inf")
    parser["test", "neginf"] = INIValue(from: "-inf")
    parser["test", "nan"] = INIValue(from: "nan")

    let inf = try parser.getDouble(section: "test", option: "inf")
    let negInf = try parser.getDouble(section: "test", option: "neginf")
    let nan = try parser.getDouble(section: "test", option: "nan")

    #expect(inf.isInfinite)
    #expect(negInf.isInfinite && negInf < 0)
    #expect(nan.isNaN)
  }

  @Test func testBooleanEdgeCases() throws {
    let parser = ConfigParser()
    parser["test", "mixed1"] = INIValue(from: "TRUE")
    parser["test", "mixed2"] = INIValue(from: "False")
    parser["test", "numeric"] = INIValue(from: "2")
    parser["test", "zero"] = INIValue(from: "0")

    #expect(try parser.getBool(section: "test", option: "mixed1") == true)
    #expect(try parser.getBool(section: "test", option: "mixed2") == false)
    #expect(try parser.getBool(section: "test", option: "numeric") == true)
    #expect(try parser.getBool(section: "test", option: "zero") == false)
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

    let opts = ConfigParserOptions(leadingSpaces: 0, trailingSpaces: 0)
    let parser1 = ConfigParser(opts)
    try parser1.read(original)

    let written = parser1.write()

    let parser2 = ConfigParser()
    try parser2.read(written)

    let key1: String = try parser2.get(section: "Section1", option: "key1")
    let key2: Bool = try parser2.get(section: "Section1", option: "key2")
    let key3: Int = try parser2.get(section: "Section2", option: "key3")

    #expect(key1 == "value1")
    #expect(key2 == true)
    #expect(key3 == 42)
  }

  @Test func testEndToEnd() throws {
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

    let parser = ConfigParser()
    try parser.set(option: "ServerAliveInterval", value: 45)
    try parser.set(option: "Compression", value: "yes")
    try parser.set(option: "CompressionLevel", value: 9)
    try parser.set(option: "ForwardX11", value: "yes")

    try parser.addSection("forge.example")
    try parser.set(section: "forge.example", option: "User", value: "hg")

    try parser.addSection("topsecret.server.example")
    try parser.set(section: "topsecret.server.example", option: "Port", value: 50022)
    try parser.set(section: "topsecret.server.example", option: "ForwardX11", value: "no")

    #expect(expected == parser.write())
    let parser2 = ConfigParser()
    try parser2.read(expected)
    #expect(parser2.write() == parser.write())

    let expectedSections = ["DEFAULT", "forge.example", "topsecret.server.example"]
    #expect(expectedSections == parser.sectionNames)

    #expect(parser.hasSection("forge.example"))
    #expect(!parser.hasSection("python.org"))
    #expect(try parser.get(section: "forge.example", option: "User") == "hg")
    #expect(try parser.get(option: "Compression") == "yes")

    #expect(try parser.get(section: "topsecret.server.example", option: "ForwardX11") == "no")
    #expect(try parser.get(section: "topsecret.server.example", option: "Port") == 50022)
  }

  @Test func testEndToEndSubscript() throws {
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

    let parser = ConfigParser()

    parser["ServerAliveInterval"] = 45
    parser["Compression"] = "yes"
    parser["CompressionLevel"] = 9
    parser["ForwardX11"] = "yes"

    parser["forge.example", "User"] = "hg"

    parser["topsecret.server.example", "Port"] = 50022
    parser["topsecret.server.example", "ForwardX11"] = "no"

    #expect(expected == parser.write())

    let parser2 = ConfigParser()
    try parser2.read(expected)
    #expect(parser2.write() == parser.write())

    let expectedSections = ["DEFAULT", "forge.example", "topsecret.server.example"]
    #expect(expectedSections == parser.sectionNames)

    #expect(parser.hasSection("forge.example"))
    #expect(!parser.hasSection("python.org"))

    #expect(parser["forge.example", "User"] == "hg")
    #expect(parser["Compression"] == "yes")

    #expect(parser["topsecret.server.example", "ForwardX11"] == "no")
    #expect(parser["topsecret.server.example", "Port"] == 50022)
  }

  @Test func readmeExample() async throws {
    let input = """
    [owner]
    name = John Doe
    organization = Acme Widgets Inc.

    [database]
    server = 192.0.2.62
    port = 143
    file = payroll.dat
    path = /var/database
    """

    let config = ConfigParser()

    try config.read(input)

    let name: String = try config.get(section: "owner", option: "name")
    #expect(name == "John Doe")

    let name2 = config["owner", "name"]?.stringValue
    #expect(name == name2)

    let server: String = try config.get(section: "database", option: "server")
    #expect(server == "192.0.2.62")

    let portValue = config["database", "port"]
    #expect(portValue?.intValue == 143)

    let nonExistent = config["database", "nonexistent"]
    #expect(nonExistent == nil)

    try config.set(section: "database", option: "file", value: "payroll_updated.data")
    let updatedFile: String = try config.get(section: "database", option: "file")
    #expect(updatedFile == "payroll_updated.data")

    config["database", "path"] = "/var/databasev2"
    let updatedPathValue = config["database", "path"]
    #expect(updatedPathValue?.stringValue == "/var/databasev2")

    let fileManager = FileManager.default
    let tempDirectoryURL = fileManager.temporaryDirectory
      .appendingPathComponent("WinnieTests-\(UUID().uuidString)", isDirectory: true)

    try fileManager.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true, attributes: nil)
    defer {
      try? fileManager.removeItem(at: tempDirectoryURL)
    }

    let tempFileURL = tempDirectoryURL.appendingPathComponent("config_test.ini")

    try config.writeFile(tempFileURL.path)

    #expect(fileManager.fileExists(atPath: tempFileURL.path))

    let configFromFile = ConfigParser()
    try configFromFile.readFile(tempFileURL.path)

    let nameFromFile: String = try configFromFile.get(section: "owner", option: "name")
    #expect(nameFromFile == "John Doe")

    let fileFromFile: String = try configFromFile.get(section: "database", option: "file")
    #expect(fileFromFile == "payroll_updated.data")

    let pathFromFileValue = configFromFile["database", "path"]
    #expect(pathFromFileValue?.stringValue == "/var/databasev2")

    let portFromFileValue = configFromFile["database", "port"]
    #expect(portFromFileValue?.intValue == 143)

    let expectedOutput = """
    [owner]
    name = John Doe
    organization = Acme Widgets Inc.

    [database]
    server = 192.0.2.62
    port = 143
    file = payroll_updated.data
    path = /var/databasev2
    """

    let outputString = config.write()
    #expect(outputString == expectedOutput)
  }

  @Test func testCustomDefaultSection() throws {
    let opts = ConfigParserOptions(defaultSection: "GLOBAL")
    let parser = ConfigParser(opts)

    #expect(parser.hasSection("GLOBAL"))

    parser["debug"] = true
    parser["app_name"] = "MyApp"

    #expect(parser["GLOBAL", "debug"] == true)
    #expect(parser["GLOBAL", "app_name"] == "MyApp")

    let debug: Bool = try parser.get(option: "debug")
    let appName: String = try parser.get(option: "app_name")

    #expect(debug == true)
    #expect(appName == "MyApp")
  }

  @Test func testCustomPadding() throws {
    let opts = ConfigParserOptions(leadingSpaces: 4, trailingSpaces: 4)
    let parser = ConfigParser(opts)

    try parser.addSection("Test")
    try parser.set(section: "Test", option: "key1", value: "value1")
    try parser.set(section: "Test", option: "key2", value: 42)

    let output = parser.write()
    let expected = """
    [Test]
    key1    =    value1
    key2    =    42
    """

    #expect(output == expected)
  }

  @Test func testCustomBooleanFormat() throws {
    let opts = ConfigParserOptions(booleanFormat: ("yes", "no"))
    let parser = ConfigParser(opts)

    try parser.addSection("Test")
    try parser.set(section: "Test", option: "enabled", value: true)
    try parser.set(section: "Test", option: "debug", value: false)

    let output = parser.write()
    let expected = """
    [Test]
    enabled = yes
    debug = no
    """

    #expect(output == expected)
  }

  @Test func testAssignmentCharacterEquals() throws {
    let opts = ConfigParserOptions(assignmentCharacter: .equals, leadingSpaces: 0)
    let parser = ConfigParser(opts)

    try parser.addSection("Test")
    try parser.set(section: "Test", option: "key1", value: "value1")
    try parser.set(section: "Test", option: "key2", value: 42)

    let output = parser.write()
    let expected = """
    [Test]
    key1=value1
    key2=42
    """

    #expect(output == expected)
  }

  @Test func testAssignmentCharacterColon() throws {
    let opts = ConfigParserOptions(assignmentCharacter: .colon)
    let parser = ConfigParser(opts)

    try parser.addSection("Test")
    try parser.set(section: "Test", option: "key1", value: "value1")
    try parser.set(section: "Test", option: "key2", value: 42)

    let output = parser.write()
    let expected = """
    [Test]
    key1: value1
    key2: 42
    """

    #expect(output == expected)
  }

  @Test func testLeadingSpacesOnly() throws {
    let opts = ConfigParserOptions(leadingSpaces: 3, trailingSpaces: nil)
    let parser = ConfigParser(opts)

    try parser.addSection("Test")
    try parser.set(section: "Test", option: "key", value: "value")

    let output = parser.write()
    #expect(output.contains("key   =   value"))
  }

  @Test func testTrailingSpacesOnly() throws {
    let opts = ConfigParserOptions(leadingSpaces: nil, trailingSpaces: 2)
    let parser = ConfigParser(opts)

    try parser.addSection("Test")
    try parser.set(section: "Test", option: "key", value: "value")

    let output = parser.write()
    #expect(output.contains("key  =  value"))
  }

  @Test func testExplicitZeroSpacing() throws {
    let opts = ConfigParserOptions(leadingSpaces: 0, trailingSpaces: 0)
    let parser = ConfigParser(opts)

    try parser.addSection("Test")
    try parser.set(section: "Test", option: "key", value: "value")

    let output = parser.write()
    #expect(output.contains("key=value"))
  }

  @Test func testLeadingTrailingSpaces() throws {
    let opts = ConfigParserOptions(leadingSpaces: 2, trailingSpaces: 4)
    let parser = ConfigParser(opts)

    try parser.addSection("Test")
    try parser.set(section: "Test", option: "key", value: "value")

    let output = parser.write()
    #expect(output.contains("key  =    value"))
  }

  @Test func testHeaderComments() throws {
    let input = """
    # This is a header comment
    # Another header comment

    [section]
    key = value
    """

    let expected = """
    # This is a header comment
    # Another header comment

    [section]
    key = value
    """

    let options = ConfigParserOptions(preserveComments: true)
    let config = ConfigParser(options)
    try config.read(input)

    let output = config.write()
    #expect(output == expected)
  }

  @Test func testCommentsBeforeSection() throws {
    let input = """
    [DEFAULT]
    default_key = default_value

    # Comment before database section
    # Another comment
    [database]
    host = localhost
    """

    let expected = """
    [DEFAULT]
    default_key = default_value

    # Comment before database section
    # Another comment
    [database]
    host = localhost
    """

    let options = ConfigParserOptions(preserveComments: true)
    let config = ConfigParser(options)
    try config.read(input)

    let output = config.write()
    #expect(output == expected)
  }

  @Test func testCommentsBeforeOption() throws {
    let input = """
    [database]
    # Comment before host option
    host = localhost
    # Comment before port option  
    port = 5432
    """

    let options = ConfigParserOptions(preserveComments: true)
    let config = ConfigParser(options)
    try config.read(input)

    let expected = """
    [database]
    # Comment before host option
    host = localhost
    # Comment before port option
    port = 5432
    """

    let output = config.write()
    #expect(output == expected)
  }

  @Test func testInlineComments() throws {
    let input = """
    [database]
    host = localhost # inline comment
    port = 5432 ; semicolon comment
    """

    let options = ConfigParserOptions(preserveComments: true)
    let config = ConfigParser(options)
    try config.read(input)

    let expected = """
    [database]
    host = localhost # inline comment
    port = 5432 ; semicolon comment
    """

    let output = config.write()
    #expect(output == expected)
  }

  @Test func testMixedCommentTypes() throws {
    let input = """
    # File header comment

    # Comment before DEFAULT section
    [DEFAULT]
    # Comment before default option
    log_level = INFO # inline comment

    # Comment before section
    [database]
    # Comment before host
    host = localhost
    port = 5432 # port comment
    """

    let options = ConfigParserOptions(preserveComments: true)
    let config = ConfigParser(options)
    try config.read(input)

    let expected = """
    # File header comment
    # Comment before DEFAULT section

    [DEFAULT]
    # Comment before default option
    log_level = INFO # inline comment

    # Comment before section
    [database]
    # Comment before host
    host = localhost
    port = 5432 # port comment
    """

    let output = config.write()
    #expect(output == expected)
  }

  @Test func testCommentPreservationDisabled() throws {
    let input = """
    # This comment should be ignored
    [section]
    # This too
    key = value # and this
    """

    let options = ConfigParserOptions(preserveComments: false)
    let config = ConfigParser(options)
    try config.read(input)

    let expected = """
    [section]
    key = value
    """

    let output = config.write()
    #expect(output == expected)
  }

  @Test func testRoundtripCommentPreservation() throws {
    let input = """
    # Header comment

    # Before DEFAULT
    [DEFAULT]
    # Before global option
    global = value # inline

    # Before section
    [test]
    # Before key
    key = value
    """

    let options = ConfigParserOptions(preserveComments: true)
    let config = ConfigParser(options)
    try config.read(input)

    let expected = """
    # Header comment
    # Before DEFAULT

    [DEFAULT]
    # Before global option
    global = value # inline

    # Before section
    [test]
    # Before key
    key = value
    """

    let firstOutput = config.write()
    #expect(firstOutput == expected)

    let config2 = ConfigParser(options)
    try config2.read(firstOutput)
    let secondOutput = config2.write()
    #expect(secondOutput == expected)
  }

  @Test func testEmptyCommentsHandling() throws {
    let input = """
    #
    [section]
    #  
    key = value #
    """

    let options = ConfigParserOptions(preserveComments: true)
    let config = ConfigParser(options)
    try config.read(input)

    let expected = """
    #

    [section]
    #
    key = value #
    """

    let output = config.write()
    #expect(output == expected)
  }

  @Test func testMultipleConsecutiveComments() throws {
    let input = """
    # Comment 1
    # Comment 2
    # Comment 3
    [section]
    # Option comment 1
    # Option comment 2
    key = value
    """

    let options = ConfigParserOptions(preserveComments: true)
    let config = ConfigParser(options)
    try config.read(input)

    let expected = """
    # Comment 1
    # Comment 2
    # Comment 3

    [section]
    # Option comment 1
    # Option comment 2
    key = value
    """

    let output = config.write()
    #expect(output == expected)
  }

  // MARK: - Comment Edge Cases

  @Test func testCommentOnlyFile() throws {
    let input = """
    # This is only comments
    # No actual config
    # Just comments everywhere
    """

    let options = ConfigParserOptions(preserveComments: true)
    let parser = try ConfigParser(input: input, options: options)

    // Should only have DEFAULT section
    #expect(parser.sectionNames.count == 1)
    #expect(parser.hasSection("DEFAULT"))

    let output = parser.write()
    #expect(output.isEmpty || !output.contains("# This is only comments"))
  }

  @Test func testCommentsWithSpecialCharacters() throws {
    let input = """
    # Comment with unicode: 🚀 ñ α β
    [section]
    # Comment with symbols: !@#$%^&*()
    key = value # Inline with unicode: 中文
    """

    let options = ConfigParserOptions(preserveComments: true)
    let config = ConfigParser(options)
    try config.read(input)

    let output = config.write()
    #expect(output.contains("🚀 ñ α β"))
    #expect(output.contains("!@#$%^&*()"))
    #expect(output.contains("中文"))
  }

  // MARK: - File I/O Error Tests

  @Test func testWriteFileInvalidPath() {
    let parser = ConfigParser()
    parser["test", "key"] = INIValue(from: "value")

    #expect(throws: Error.self) {
      try parser.writeFile("/nonexistent/deeply/nested/path/that/does/not/exist/file.ini")
    }
  }
}
