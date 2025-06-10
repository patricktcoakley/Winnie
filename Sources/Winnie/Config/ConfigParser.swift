import Foundation
import OrderedCollections

public typealias Section = OrderedDictionary<String, INIValue>
public typealias Config = OrderedDictionary<String, Section>

public final class ConfigParser {
  var config: Config = [:]
  private let options: ConfigParserOptions

  public init(_ options: ConfigParserOptions = ConfigParserOptions()) {
    self.options = options
    config[self.options.defaultSection] = [:]
  }

  public init(file path: String, options: ConfigParserOptions) throws {
    self.options = options
    config[self.options.defaultSection] = [:]
    try readFile(path)
  }

  public init(input string: String, options: ConfigParserOptions) throws {
    self.options = options
    config[self.options.defaultSection] = [:]
    try read(string)
  }

  public var sections: SectionProxySequence { SectionProxySequence(parser: self) }
  public var sectionNames: [String] { Array(config.keys) }

  public subscript(section: String) -> SectionProxy? {
    guard config[section] != nil else { return nil }
    return SectionProxy(section: section, parser: self)
  }

  public subscript(option: String) -> INIValue? {
    get { config[self.options.defaultSection]?[option] }

    set {
      if config[self.options.defaultSection] == nil {
        config[self.options.defaultSection] = [:]
      }

      if let newValue {
        config[self.options.defaultSection]?[option] = newValue
        return
      }

      config[self.options.defaultSection]?.removeValue(forKey: option)
    }
  }

  public subscript(section: String, option: String) -> INIValue? {
    get {
      if let sectionValue = config[section]?[option] {
        return sectionValue
      }

      if section != self.options.defaultSection {
        return config[self.options.defaultSection]?[option]
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

  public func items(section: String) throws(ConfigParserError) -> any MutableCollection {
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
    try get(section: self.options.defaultSection, option: option)
  }

  public func get<T: INIValueConvertible>(section: String, option: String, default defaultValue: T) -> T {
    (try? get(section: section, option: option)) ?? defaultValue
  }

  public func get<T: INIValueConvertible>(option: String, default defaultValue: T) -> T {
    get(section: self.options.defaultSection, option: option, default: defaultValue)
  }

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

  public func set(section: String, option: String, value: some INIValueConvertible) throws(ConfigParserError) {
    if config[section] == nil {
      throw ConfigParserError.sectionNotFound(section)
    }

    config[section]![option] = value.into()
  }

  public func set(option: String, value: some INIValueConvertible) throws(ConfigParserError) {
    try set(section: self.options.defaultSection, option: option, value: value)
  }

  public func addSection(_ section: String) throws(ConfigParserError) {
    guard section != self.options.defaultSection else {
      throw ConfigParserError.valueError("Cannot add default section.")
    }

    guard config[section] == nil else {
      throw ConfigParserError.valueError("Section \(section) already exists.")
    }

    config[section] = [:]
  }

  public func removeSection(_ section: String) throws(ConfigParserError) {
    guard section != self.options.defaultSection else {
      throw ConfigParserError.valueError("Cannot remove default section.")
    }

    config.removeValue(forKey: section)
  }

  public func hasSection(_ section: String) -> Bool { config[section] != nil }

  public func readFile(_ path: String) throws {
    let contents = try String(contentsOfFile: path)
    try read(contents)
  }

  public func read(_ contents: String) throws {
    var tokenizer = Tokenizer(contents)
    let tokens = try tokenizer.tokenize()
    var index = tokens.startIndex
    var currentSection = self.options.defaultSection
    var newConfig: Config = [self.options.defaultSection: [:]]

    while index < tokens.endIndex {
      let token = tokens[index]

      switch token {
      case let .section(section):
        currentSection = section
        if currentSection != self.options.defaultSection {
          newConfig[currentSection] = [:]
        }

        index = tokens.index(after: index)

      case let .string(option):
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

  public func write() -> String {
    let leadingSpaces = String(repeating: " ", count: self.options.leadingSpaces)
    let trailingSpaces = String(repeating: " ", count: self.options.trailingSpaces)

    let assignment = "\(leadingSpaces)\(self.options.assignmentCharacter.rawValue)\(trailingSpaces)"

    var output = ""

    if let defaultSection = config[self.options.defaultSection], !defaultSection.isEmpty {
      output += "[\(self.options.defaultSection)]\n"
      for (option, value) in defaultSection {
        output += "\(option)\(assignment)\(value.description)\n"
      }

      // Only add a newline if defaultSection isn't the only section and isnt empty
      if !defaultSection.isEmpty, config.keys.count > 1 {
        output += "\n"
      }
    }

    for section in sectionNames where section != self.options.defaultSection {
      output += "[\(section)]\n"

      if let sectionData = config[section] {
        for (option, value) in sectionData {
          output += "\(option)\(assignment)\(value.description)\n"
        }
      }
      output += "\n"
    }

    return output.trimmingCharacters(in: .newlines)
  }

  private func isAssignmentToken(_ token: Token) -> Bool {
    switch token {
    case .equals, .colon: true
    default: false
    }
  }
}
