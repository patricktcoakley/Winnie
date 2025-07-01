import OrderedCollections

// MARK: - SectionProxy

/// A proxy for accessing and modifying options within a specific INI section.
///
/// `SectionProxy` provides a convenient interface for working with options and values
/// within a section, including subscript access and iteration over option-value pairs.
///
/// ## Usage
///
/// ```swift
/// let parser = ConfigParser()
/// try parser.addSection("database")
///
/// if let dbSection = parser["database"] {
///   // Set values using subscript
///   dbSection["host"] = "localhost"
///   dbSection["port"] = 5432
///
///   // Get values using subscript
///   let host = dbSection["host"]
///
///   // Iterate over all option-value pairs
///   for (option, value) in dbSection {
///     print("\(option) = \(value)")
///   }
/// }
/// ```
public struct SectionProxy {
  /// The name of the section this proxy represents.
  public let section: String
  unowned var parser: ConfigParser

  init(section: String, parser: ConfigParser) {
    self.section = section
    self.parser = parser
  }

  /// Accesses the value for the specified option in this section.
  ///
  /// - Parameter option: The name of the option to access.
  /// - Returns: The `INIValue` for the option, or `nil` if the option doesn't exist.
  public subscript(option: String) -> INIValue? {
    get { parser[section, option] }
    set { parser[section, option] = newValue }
  }

  /// A collection of all option names in this section.
  public var options: some Collection<String> { parser.config[section]?.keys ?? [] }

  /// An array of all values in this section.
  public var values: [INIValue] {
    if let valuesCollection = parser.config[section]?.values {
      return Array(valuesCollection)
    }
    return []
  }
}

// MARK: - Sequence Conformance

extension SectionProxy: Sequence {
  public typealias Element = SectionPair

  public func makeIterator() -> SectionPairIterator {
    SectionPairIterator(sectionProxy: self)
  }
}

public struct SectionPairIterator: IteratorProtocol {
  public typealias Element = SectionPair

  private let sectionProxy: SectionProxy
  private var optionIterator: any IteratorProtocol<String>

  init(sectionProxy: SectionProxy) {
    self.sectionProxy = sectionProxy
    self.optionIterator = sectionProxy.options.makeIterator()
  }

  public mutating func next() -> Element? {
    guard let option = optionIterator.next(),
          let value = sectionProxy[option]
    else {
      return nil
    }
    return (option: option, value: value)
  }
}

// MARK: - SectionProxyIterator

public struct SectionProxyIterator: IteratorProtocol {
  public typealias Element = SectionProxy

  unowned let parser: ConfigParser
  var sectionNameIterator: any IteratorProtocol<String>

  init(parser: ConfigParser) {
    self.parser = parser
    sectionNameIterator = parser.config.keys.makeIterator()
  }

  public mutating func next() -> Element? {
    guard let sectionName = sectionNameIterator.next() else { return nil }
    return SectionProxy(section: sectionName, parser: parser)
  }
}

// MARK: - SectionProxySequence

public struct SectionProxySequence: Sequence {
  public typealias Element = SectionProxy
  public typealias Iterator = SectionProxyIterator

  unowned let parser: ConfigParser

  init(parser: ConfigParser) {
    self.parser = parser
  }

  public func makeIterator() -> Iterator { SectionProxyIterator(parser: parser) }
}
