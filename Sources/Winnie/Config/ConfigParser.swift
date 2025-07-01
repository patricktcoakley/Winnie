import Foundation
import OrderedCollections

/// A parser for INI configuration files.
///
/// `ConfigParser` provides a way to read, write, and manipulate INI files with support
/// for sections, options, and values. It follows standard INI file conventions and
/// provides type-safe value conversion.
///
/// ## Usage
///
/// ```swift
/// let parser = ConfigParser()
/// try parser.addSection("database")
/// parser["database", "host"] = "localhost"
/// parser["database", "port"] = 5432
///
/// let host: String = try parser.getString(section: "database", option: "host")
/// let port: Int = try parser.getInt(section: "database", option: "port")
/// ```
public final class ConfigParser {
  var config = Config()
  private let options: ConfigParserOptions

  // MARK: - Initialization

  /// Creates a new configuration parser with the specified options.
  ///
  /// - Parameter options: Configuration options for parsing behavior. Defaults to standard settings.
  public init(_ options: ConfigParserOptions = ConfigParserOptions()) {
    self.options = options
    config[self.options.defaultSection] = [:]
  }

  /// Creates a new configuration parser and loads data from a file.
  ///
  /// - Parameters:
  ///   - path: The file path to read the configuration from.
  ///   - options: Configuration options for parsing behavior.
  /// - Throws: `ConfigParserError` if the file cannot be read or parsed.
  public init(file path: String, options: ConfigParserOptions) throws {
    self.options = options
    config[self.options.defaultSection] = [:]
    try readFile(path)
  }

  /// Creates a new configuration parser and loads data from a string.
  ///
  /// - Parameters:
  ///   - string: The INI content as a string.
  ///   - options: Configuration options for parsing behavior.
  /// - Throws: `ConfigParserError` if the content cannot be parsed.
  public init(input string: String, options: ConfigParserOptions) throws {
    self.options = options
    config[self.options.defaultSection] = [:]
    try read(string)
  }

  // MARK: - Properties

  /// A sequence of all sections in the configuration.
  ///
  /// Use this property to iterate over all sections:
  /// ```swift
  /// for section in parser.sections {
  ///   print("Section: \(section.section)")
  /// }
  /// ```
  public var sections: SectionProxySequence { SectionProxySequence(parser: self) }

  /// An array of all section names in the configuration.
  public var sectionNames: [String] { Array(config.keys) }

  // MARK: - Subscripts

  /// Accesses a section proxy for the specified section.
  ///
  /// - Parameter section: The name of the section to access.
  /// - Returns: A `SectionProxy` for the section, or `nil` if the section doesn't exist.
  public subscript(section: String) -> SectionProxy? {
    guard config[section] != nil else { return nil }
    return SectionProxy(section: section, parser: self)
  }

  /// Accesses the value for an option in the default section.
  ///
  /// Setting a value will automatically create the default section if it doesn't exist.
  ///
  /// - Parameter option: The name of the option to access.
  /// - Returns: The `INIValue` for the option, or `nil` if the option doesn't exist.
  public subscript(option: String) -> INIValue? {
    get { config[options.defaultSection]?[option] }

    set {
      if config[options.defaultSection] == nil {
        config[options.defaultSection] = [:]
      }

      if let newValue {
        config[options.defaultSection]?[option] = newValue
        return
      }

      config[options.defaultSection]?.removeValue(forKey: option)
    }
  }

  /// Accesses the value for an option in the specified section.
  ///
  /// Setting a value will automatically create both the section and option if they don't exist.
  /// This differs from the `set(section:option:value:)` method which throws an error if the section doesn't exist.
  ///
  /// - Parameters:
  ///   - section: The name of the section containing the option.
  ///   - option: The name of the option to access.
  /// - Returns: The `INIValue` for the option, or `nil` if the option doesn't exist.
  public subscript(section: String, option: String) -> INIValue? {
    get {
      if let sectionValue = config[section]?[option] {
        return sectionValue
      }

      if section != options.defaultSection {
        return config[options.defaultSection]?[option]
      }

      return nil
    }

    set {
      if config[section] == nil {
        config[section] = [:]
      }

      if let newValue {
        config[section]?[option] = newValue
        return
      }

      config[section]?.removeValue(forKey: option)
    }
  }

  // MARK: - Value Retrieval

  public func items(section: String) throws(ConfigParserError) -> SectionValues {
    if let values = config[section] {
      return values.values
    }

    throw .sectionNotFound(section)
  }

  public func get<T: INIValueConvertible>(section: String, option: String) throws(ConfigParserError) -> T {
    if let section = config[section] {
      guard let value = section[option] else { throw .optionNotFound(option) }
      return try T.from(value)
    }

    throw .sectionNotFound(section)
  }

  public func get<T: INIValueConvertible>(option: String) throws(ConfigParserError) -> T {
    try get(section: options.defaultSection, option: option)
  }

  public func get<T: INIValueConvertible>(section: String, option: String, default defaultValue: T) -> T {
    (try? get(section: section, option: option)) ?? defaultValue
  }

  public func get<T: INIValueConvertible>(option: String, default defaultValue: T) -> T {
    get(section: options.defaultSection, option: option, default: defaultValue)
  }

  // MARK: - Type-Specific Getters

  public func getBool(section: String, option: String) throws(ConfigParserError) -> Bool {
    try get(section: section, option: option)
  }

  public func getString(section: String, option: String) throws(ConfigParserError) -> String {
    try get(section: section, option: option)
  }

  public func getInt(section: String, option: String) throws(ConfigParserError) -> Int {
    try get(section: section, option: option)
  }

  public func getDouble(section: String, option: String) throws(ConfigParserError) -> Double {
    try get(section: section, option: option)
  }

  // MARK: - Value Setting

  public func set(section: String, option: String, value: some INIValueConvertible) throws(ConfigParserError) {
    if config[section] == nil {
      throw ConfigParserError.sectionNotFound(section)
    }

    config[section]![option] = value.into()
  }

  public func set(option: String, value: some INIValueConvertible) throws(ConfigParserError) {
    try set(section: options.defaultSection, option: option, value: value)
  }

  // MARK: - Section Management

  public func addSection(_ section: String) throws(ConfigParserError) {
    guard section != options.defaultSection else {
      throw ConfigParserError.valueError("Cannot add default section.")
    }

    guard config[section] == nil else {
      throw ConfigParserError.valueError("Section \(section) already exists.")
    }

    config[section] = [:]
  }

  public func removeSection(_ section: String) throws(ConfigParserError) {
    guard section != options.defaultSection else {
      throw ConfigParserError.valueError("Cannot remove default section.")
    }

    _ = config.removeValue(forKey: section)
  }

  public func hasSection(_ section: String) -> Bool { config[section] != nil }

  // MARK: - File I/O

  public func readFile(_ path: String) throws {
    let contents = try String(contentsOfFile: path)
    try read(contents)
  }

  public func read(_ contents: String) throws {
    var tokenizer = Tokenizer(contents)
    let tokens = try tokenizer.tokenize()
    var index = tokens.startIndex
    var currentSection = options.defaultSection
    var newConfig = Config()
    newConfig[options.defaultSection] = [:]
    var commentBuffer: [String] = []
    var hasSeenSection = false

    while index < tokens.endIndex {
      let token = tokens[index]

      switch token {
      case let .comment(comment):
        commentBuffer.append(comment)
        index = tokens.index(after: index)

      case let .section(section):
        if !hasSeenSection, !commentBuffer.isEmpty {
          for comment in commentBuffer {
            newConfig.addHeaderComment(comment)
          }
        } else if !commentBuffer.isEmpty {
          newConfig.addBeforeSectionComments(commentBuffer, for: section)
        }
        commentBuffer = []
        hasSeenSection = true
        currentSection = section
        if currentSection != options.defaultSection {
          newConfig[currentSection] = [:]
        }
        index = tokens.index(after: index)

      case let .string(option):
        if !commentBuffer.isEmpty, options.preserveComments {
          newConfig.addBeforeOptionComments(commentBuffer, for: option, in: currentSection)
        }
        commentBuffer = []
        index = tokens.index(after: index)

        if index < tokens.endIndex, isAssignmentToken(tokens[index]) {
          index = tokens.index(after: index)

          let value = if index < tokens.endIndex, case let .string(string) = tokens[index] {
            string.trimmingCharacters(in: .whitespacesAndNewlines)
          } else {
            ""
          }

          newConfig[currentSection]?[option] = value.into()

          if index < tokens.endIndex, case .string = tokens[index] {
            index = tokens.index(after: index)
          }

          // Check for inline comment after value
          if index < tokens.endIndex, case let .comment(inlineComment) = tokens[index], options.preserveComments {
            newConfig.addInlineComment(inlineComment, for: option, in: currentSection)
            index = tokens.index(after: index)
          }
        } else {
          newConfig[currentSection]?[option] = ""
        }

      default:
        index = tokens.index(after: index)
      }
    }

    config = newConfig
  }

  public func writeFile(_ path: String) throws {
    try write().write(toFile: path, atomically: true, encoding: .utf8)
  }

  public func write() -> String { config.write(with: options) }

  // MARK: - Private Helpers

  private func isAssignmentToken(_ token: Token) -> Bool {
    switch token {
    case .equals, .colon: true
    default: false
    }
  }
}
