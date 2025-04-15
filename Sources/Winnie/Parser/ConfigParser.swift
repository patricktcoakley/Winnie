import Foundation
import OrderedCollections

public typealias Section = OrderedDictionary<String, INIValue>
public typealias Config = OrderedDictionary<String, Section>

public enum AssignmentCharacter: String {
  case equals = "="
  case colon = ":"
}

public final class ConfigParser {
  private(set) var config: Config = [:]
  private static let DEFAULT_SECTION = "DEFAULT"

  public init() {
    config[Self.DEFAULT_SECTION] = [:]
  }

  public var sections: [String] { Array(config.keys) }

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
    return try get(section: Self.DEFAULT_SECTION, option: option)
  }

  public func get<T: INIValueConvertible>(section: String, option: String, default defaultValue: T) -> T {
    return (try? get(section: section, option: option)) ?? defaultValue
  }

  public func get<T: INIValueConvertible>(option: String, default defaultValue: T) -> T {
    return get(section: Self.DEFAULT_SECTION, option: option, default: defaultValue)
  }

  public func set<T: INIValueConvertible>(section: String, option: String, value: T) {
    if config[section] == nil {
      config[section] = [:]
    }

    config[section]?[option] = value.into()
  }

  public func set<T: INIValueConvertible>(option: String, value: T) {
    set(section: Self.DEFAULT_SECTION, option: option, value: value)
  }

  public func addSection(_ section: String) throws(ConfigParserError) {
    guard section != Self.DEFAULT_SECTION else {
      throw ConfigParserError.valueError("Cannot add default section.")
    }

    guard config[section] == nil else {
      throw ConfigParserError.valueError("Section \(section) already exists.")
    }

    config[section] = [:]
  }

  public func removeSection(_ section: String) throws(ConfigParserError) {
    guard section != Self.DEFAULT_SECTION else {
      throw ConfigParserError.valueError("Cannot remove default section.")
    }

    config.removeValue(forKey: section)
  }

  public func hasSection(_ section: String) -> Bool { return config[section] != nil }

  public func readFile(_ path: String) throws {
    let contents = try String(contentsOfFile: path)
    try read(contents)
  }

  public func read(_ contents: String) throws {
    let tokenizer = Tokenizer(contents)
    let tokens = try tokenizer.tokenize()
    var index = tokens.startIndex
    var currentSection = Self.DEFAULT_SECTION

    while index < tokens.endIndex {
      let token = tokens[index]

      switch token {
      // Begin section
      case .leftBracket:
        index = tokens.index(after: index)

        guard index < tokens.endIndex, case let .string(section) = tokens[index] else {
          index = tokens.index(after: index)
          continue
        }

        currentSection = section
        if currentSection != Self.DEFAULT_SECTION {
          try addSection(section)
        }

        index = tokens.index(after: index)

        // End section
        if index < tokens.endIndex, tokens[index] == .rightBracket {
          index = tokens.index(after: index)
        }

      case let .string(option):
        index = tokens.index(after: index)
        guard index < tokens.endIndex else { break }

        if tokens[index] == .equals || tokens[index] == .colon {
          index = tokens.index(after: index)
          guard index < tokens.endIndex else { break }

          let value: String = if case let .string(string) = tokens[index] { string } else { "" }
          index = tokens.index(after: index)
          set(section: currentSection, option: option, value: value)
        }

      default:
        index = tokens.index(after: index)
      }
    }
  }

  public func writeFile(_ path: String) throws {
    try write().write(toFile: path, atomically: true, encoding: .utf8)
  }

  public func write(assignment: AssignmentCharacter = .equals, leadingSpaces: Bool = true) -> String {
    var output = ""

    if let defaultSection = config[Self.DEFAULT_SECTION], !defaultSection.isEmpty {
      output += "[DEFAULT]\n"
      for (option, value) in defaultSection {
        output += "\(option)"
        output += leadingSpaces ? " \(assignment.rawValue) " : "\(assignment.rawValue)"
        output += "\(value.description)\n"
      }
      output += "\n"
    }

    for section in sections where section != Self.DEFAULT_SECTION {
      output += "[\(section)]\n"

      if let sectionData = config[section] {
        for (option, value) in sectionData {
          output += "\(option)"
          output += leadingSpaces ? " \(assignment.rawValue) " : "\(assignment.rawValue)"
          output += "\(value.description)\n"
        }
      }
      output += "\n"
    }

    return output.trimmingCharacters(in: .newlines)
  }
}
