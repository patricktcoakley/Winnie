import Foundation
import OrderedCollections

/// An ordered dictionary representing a section in an INI file, mapping option names to their values.
public typealias Section = OrderedDictionary<String, INIValue>

/// A collection of values from a section, maintaining the order of options.
public typealias SectionValues = OrderedDictionary<String, INIValue>.Values

/// A tuple representing an option-value pair within a section.
public typealias SectionPair = (option: String, value: INIValue)

public struct Config {
  private var sections: OrderedDictionary<String, Section> = [:]
  private var comments = Comments()

  public init() {}

  // MARK: - Public Dictionary-like Interface

  public subscript(key: String) -> Section? {
    get { sections[key] }
    set { sections[key] = newValue }
  }

  public var keys: some Collection<String> { sections.keys }
  public var count: Int { sections.count }
  public var isEmpty: Bool { sections.isEmpty }

  public mutating func removeValue(forKey key: String) -> Section? {
    sections.removeValue(forKey: key)
  }

  public func contains(_ key: String) -> Bool {
    sections.keys.contains(key)
  }

  // MARK: - Internal Comment Management

  mutating func addHeaderComment(_ comment: String) {
    comments.addHeaderComment(comment)
  }

  mutating func addBeforeSectionComments(_ commentList: [String], for section: String) {
    comments.addBeforeSectionComments(commentList, for: section)
  }

  mutating func addBeforeOptionComments(_ commentList: [String], for option: String, in section: String) {
    comments.addBeforeOptionComments(commentList, for: option, in: section)
  }

  mutating func addInlineComment(_ comment: String, for option: String, in section: String) {
    comments.addInlineComment(comment, for: option, in: section)
  }

  var headerComments: [String] {
    comments.headerComments
  }

  // MARK: - Internal Write Method

  func write(with options: ConfigParserOptions) -> String {
    let leadingSpaces = String(repeating: " ", count: options.leadingSpaces)
    let trailingSpaces = String(repeating: " ", count: options.trailingSpaces)
    let assignment = "\(leadingSpaces)\(options.assignmentCharacter.rawValue)\(trailingSpaces)"

    var output = ""

    // Add header comments
    if options.preserveComments {
      for comment in headerComments {
        output += "\(comment)\n"
      }
      if !headerComments.isEmpty {
        output += "\n"
      }
    }

    if let defaultSection = sections[options.defaultSection], !defaultSection.isEmpty {
      // Comments before default section
      if options.preserveComments {
        for comment in comments[options.defaultSection] {
          output += "\(comment)\n"
        }
      }

      output += "[\(options.defaultSection)]\n"
      for (option, value) in defaultSection {
        // Comments before option
        if options.preserveComments {
          for comment in comments[options.defaultSection, option] {
            output += "\(comment)\n"
          }
        }

        output += "\(option)\(assignment)\(value.description(booleanFormat: options.booleanFormat))"

        // Inline comment
        if options.preserveComments, let inlineComment = comments.inlineComment(for: option, in: options.defaultSection) {
          output += " \(inlineComment)"
        }

        output += "\n"
      }

      // Only add a newline if defaultSection isn't the only section and isnt empty
      if !defaultSection.isEmpty, sections.keys.count > 1 {
        output += "\n"
      }
    }

    for sectionName in keys where sectionName != options.defaultSection {
      // Comments before section
      if options.preserveComments {
        for comment in comments[sectionName] {
          output += "\(comment)\n"
        }
      }

      output += "[\(sectionName)]\n"

      if let sectionData = sections[sectionName] {
        for (option, value) in sectionData {
          // Comments before option
          if options.preserveComments {
            for comment in comments[sectionName, option] {
              output += "\(comment)\n"
            }
          }

          output += "\(option)\(assignment)\(value.description(booleanFormat: options.booleanFormat))"

          // Inline comment
          if options.preserveComments, let inlineComment = comments.inlineComment(for: option, in: sectionName) {
            output += " \(inlineComment)"
          }

          output += "\n"
        }
      }
      output += "\n"
    }

    return output.trimmingCharacters(in: .newlines)
  }

  // MARK: - Private Nested Comment Storage

  private struct Comments {
    // MARK: - Comment Key Types

    private enum CommentKey: Hashable {
      case section(String)
      case option(section: String, option: String)
      case inline(section: String, option: String)
    }

    // MARK: - Storage Properties

    private var headers: [String] = []
    private var storage: [CommentKey: String] = [:]

    // MARK: - Comment Addition Methods

    mutating func addHeaderComment(_ comment: String) {
      headers.append(comment)
    }

    mutating func addBeforeSectionComments(_ commentList: [String], for section: String) {
      let combined = commentList.joined(separator: "\n")
      storage[.section(section)] = combined
    }

    mutating func addBeforeOptionComments(_ commentList: [String], for option: String, in section: String) {
      let combined = commentList.joined(separator: "\n")
      storage[.option(section: section, option: option)] = combined
    }

    mutating func addInlineComment(_ comment: String, for option: String, in section: String) {
      storage[.inline(section: section, option: option)] = comment
    }

    // MARK: - Comment Access Methods

    var headerComments: [String] {
      headers
    }

    subscript(section: String) -> [String] {
      guard let text = storage[.section(section)] else { return [] }
      return text.components(separatedBy: "\n")
    }

    subscript(section: String, option: String) -> [String] {
      guard let text = storage[.option(section: section, option: option)] else { return [] }
      return text.components(separatedBy: "\n")
    }

    func inlineComment(for option: String, in section: String) -> String? {
      storage[.inline(section: section, option: option)]
    }
  }
}
