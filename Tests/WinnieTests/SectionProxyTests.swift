import Testing
@testable import Winnie

struct SectionProxyTests {
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
}
