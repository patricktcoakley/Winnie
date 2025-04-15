import OrderedCollections

public struct SectionProxy {
  let section: String
  unowned var parser: ConfigParser

  init(section: String, parser: ConfigParser) {
    self.section = section
    self.parser = parser
  }

  public subscript(option: String) -> INIValue? {
    get { parser[section, option] }
    set { parser[section, option] = newValue }
  }

  public var options: OrderedSet<String> { parser.config[section]?.keys ?? [] }

  public var values: [INIValue] {
    if let valuesCollection = parser.config[section]?.values {
      return Array(valuesCollection)
    }
    return []
  }
}

public struct SectionProxyIterator: IteratorProtocol {
  public typealias Element = SectionProxy

  unowned let parser: ConfigParser
  var keyIterator: IndexingIterator<OrderedSet<String>>

  init(parser: ConfigParser) {
    self.parser = parser
    keyIterator = parser.config.keys.makeIterator()
  }

  public mutating func next() -> Element? {
    guard let sectionKey = keyIterator.next() else { return nil }
    return SectionProxy(section: sectionKey, parser: parser)
  }
}

public struct SectionProxySequence: Sequence {
  public typealias Element = SectionProxy
  public typealias Iterator = SectionProxyIterator

  unowned let parser: ConfigParser

  init(parser: ConfigParser) {
    self.parser = parser
  }

  public func makeIterator() -> Iterator { SectionProxyIterator(parser: parser) }
}
