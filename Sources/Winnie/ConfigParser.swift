import Foundation
import OrderedCollections

public protocol CustomINIValueConvertible {
  func into() -> INIValue
  static func from(_ value: INIValue) throws(ConfigParserError) -> Self
}

extension String: CustomINIValueConvertible {
  public func into() -> INIValue { .string(self) }

  public static func from(_ value: INIValue) throws(ConfigParserError) -> String {
    return switch value {
    case let .string(string): string
    default: value.description
    }
  }
}

extension Bool: CustomINIValueConvertible {
  public func into() -> INIValue { .bool(self) }

  public static func from(_ value: INIValue) throws(ConfigParserError) -> Bool {
    return switch value {
    case let .bool(bool): bool
    case let .string(string):
      switch string.lowercased() {
      case "true", "yes", "1", "on": true
      case "false", "no", "0", "off": false
      default: true
      }
    case let .double(t): t > 0.0
    case let .int(i): i > 0
    }
  }
}

extension Int: CustomINIValueConvertible {
  public func into() -> INIValue { .int(self) }

  public static func from(_ value: INIValue) throws(ConfigParserError) -> Int {
    switch value {
    case let .int(int): return int
    case let .bool(bool): return !bool ? 0 : 1
    case let .double(double): return Int(double)
    case let .string(string):
      guard let result = Int(string) else {
        throw ConfigParserError.valueError("Cannot convert to Int: \(string)")
      }
      return result
    }
  }
}

extension Double: CustomINIValueConvertible {
  public func into() -> INIValue { .double(self) }

  public static func from(_ value: INIValue) throws(ConfigParserError) -> Double {
    switch value {
    case let .double(double): return double
    case let .int(int): return Double(int)
    case let .bool(bool): return !bool ? 0.0 : 1.0
    case let .string(string):
      guard let result = Double(string) else {
        throw ConfigParserError.valueError("Cannot convert to Double: \(string)")
      }
      return result
    }
  }
}

public enum INIValue: CustomStringConvertible, CustomINIValueConvertible {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)

  public init(from string: String) {
    if let anInt = Int(string) {
      self = .int(anInt)
      return
    }

    if let aDouble = Double(string) {
      self = .double(aDouble)
      return
    }

    switch string.lowercased() {
    case "true", "yes", "1", "on":
      self = .bool(true)
      return
    case "false", "no", "0", "off":
      self = .bool(false)
      return
    default:
      self = .string(string)
    }
  }

  public var description: String {
    return switch self {
    case let .string(value): value
    case let .int(value): String(value)
    case let .double(value): String(value)
    case let .bool(value): value ? "True" : "False"
    }
  }

  public func into() -> INIValue { self }
  public static func from(_ value: INIValue) throws(ConfigParserError) -> Self { value }
}

public enum AssignmentCharacter: String {
  case equals = "="
  case colon = ":"
}

public typealias Section = OrderedDictionary<String, INIValue>
public typealias Config = OrderedDictionary<String, Section>

public class ConfigParser {
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

  public func get<T: CustomINIValueConvertible>(section: String, option: String) throws(ConfigParserError) -> T {
    if let section = config[section] {
      guard let value = section[option] else { throw .optionNotFound(option) }
      return try T.from(value)
    }

    throw .sectionNotFound(section)
  }

  public func get<T: CustomINIValueConvertible>(option: String) throws(ConfigParserError) -> T {
    return try get(section: Self.DEFAULT_SECTION, option: option)
  }

  public func set<T: CustomINIValueConvertible>(section: String, option: String, value: T) {
    if config[section] == nil {
      config[section] = [:]
    }

    config[section]?[option] = value.into()
  }

  public func set<T: CustomINIValueConvertible>(option: String, value: T) {
    set(section: Self.DEFAULT_SECTION, option: option, value: value)
  }

  public subscript(section: String) -> Section? {
    get { config[section] }
    set { config[section] = newValue }
  }

  public func addSection(_ section: String) throws(ConfigParserError) {
    guard section != Self.DEFAULT_SECTION else { throw ConfigParserError.valueError("Cannot add default section.") }

    guard config[section] == nil else { throw ConfigParserError.valueError("Section \(section) already exists.") }

    config[section] = [:]
  }

  public func removeSection(_ section: String) throws(ConfigParserError) {
    guard section != Self.DEFAULT_SECTION else { throw ConfigParserError.valueError("Cannot remove default section.") }

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
        try addSection(section)

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

public enum ConfigParserError: Error, Equatable {
  case sectionNotFound(String)
  case optionNotFound(String)
  case valueError(String)
}
