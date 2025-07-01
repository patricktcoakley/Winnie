import Testing
@testable import Winnie

struct SectionProxyTests {
  // MARK: - Subscript and Property Tests

  @Test func sectionProxySubscript() throws {
    let parser = ConfigParser()
    try parser.addSection("test")
    parser["test", "key"] = "value"

    if var proxy: SectionProxy = parser["test"] {
      #expect(proxy["key"]?.stringValue == "value")

      proxy["newKey"] = "newValue"
      #expect(parser["test", "newKey"]?.stringValue == "newValue")
    } else {
      Issue.record("Expected proxy to exist")
    }
  }

  @Test func sectionProxyOptions() throws {
    let parser = ConfigParser()
    try parser.addSection("test")
    parser["test", "key1"] = "value1"
    parser["test", "key2"] = "value2"

    if let proxy: SectionProxy = parser["test"] {
      let expectedOptions = Set(["key1", "key2"])
      let actualOptions = Set(proxy.options)
      #expect(actualOptions == expectedOptions)
    } else {
      Issue.record("Expected proxy to exist")
    }
  }

  @Test func sectionProxyValues() throws {
    let parser = ConfigParser()
    try parser.addSection("test")
    parser["test", "key1"] = "value1"
    parser["test", "key2"] = "value2"

    if let proxy: SectionProxy = parser["test"] {
      #expect(proxy.values.count == 2)
    } else {
      Issue.record("Expected proxy to exist")
    }
  }

  // MARK: - Iteration Tests

  @Test func sectionProxyIteration() throws {
    let parser = ConfigParser()
    try parser.addSection("section1")
    try parser.addSection("section2")
    parser["section1", "key1"] = "value1"
    parser["section2", "key2"] = "value2"

    var sections: [String] = []
    for section in parser.sections {
      sections.append(section.section)
    }

    #expect(sections.contains("DEFAULT"))
    #expect(sections.contains("section1"))
    #expect(sections.contains("section2"))
  }

  @Test func sectionProxyOptionValueIteration() throws {
    let parser = ConfigParser()
    try parser.addSection("test")
    parser["test", "host"] = "localhost"
    parser["test", "port"] = 5432
    parser["test", "ssl"] = true

    if let proxy: SectionProxy = parser["test"] {
      var pairs: [SectionPair] = []
      for (option, value) in proxy {
        pairs.append((option, value))
      }

      #expect(pairs.count == 3)

      // Check that all expected options are present
      let options = pairs.map(\.option)
      #expect(options.contains("host"))
      #expect(options.contains("port"))
      #expect(options.contains("ssl"))

      // Check specific values
      let values = Dictionary(uniqueKeysWithValues: pairs.map { ($0.option, $0.value) })
      #expect(values["host"] == .string("localhost"))
      #expect(values["port"] == .int(5432))
      #expect(values["ssl"] == .bool(true))
    } else {
      Issue.record("Expected proxy to exist")
    }
  }
}
