/// A type-safe representation of values in INI files.
///
/// `INIValue` can hold strings, integers, doubles, or booleans, providing automatic
/// type inference from string input and safe conversion between types.
///
/// ## Creating Values
///
/// ```swift
/// let stringValue = INIValue(from: "hello")      // .string("hello")
/// let intValue = INIValue(from: "42")            // .int(42)
/// let doubleValue = INIValue(from: "3.14")       // .double(3.14)
/// let boolValue = INIValue(from: "true")         // .bool(true)
/// ```
///
/// ## Type Conversion
///
/// ```swift
/// let value = INIValue(from: "42")
/// let asInt = value.intValue        // 42
/// let asString = value.stringValue  // "42"
/// ```
public enum INIValue: Equatable {
  case string(String)
  case int(Int)
  case double(Double)
  case bool(Bool)

  // MARK: - Initialization

  /// Creates an `INIValue` by inferring the type from a string.
  ///
  /// The initializer attempts to parse the string as an integer, then a double,
  /// then a boolean, falling back to a string if none match.
  ///
  /// - Parameter string: The string to parse.
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

  // MARK: - Computed Properties

  /// The value as an `Int`, or `nil` if conversion fails.
  ///
  /// Conversion rules:
  /// - `.int(value)` returns the value directly
  /// - `.bool(true)` returns 1, `.bool(false)` returns 0
  /// - `.double(value)` returns the truncated integer if finite and within Int range
  /// - `.string(value)` attempts to parse the string as an integer
  public var intValue: Int? { try? Int.from(self) }

  /// The value as a `Double`, or `nil` if conversion fails.
  ///
  /// Conversion rules:
  /// - `.double(value)` returns the value directly
  /// - `.int(value)` converts to double
  /// - `.bool(true)` returns 1.0, `.bool(false)` returns 0.0
  /// - `.string(value)` attempts to parse the string as a double
  public var doubleValue: Double? { try? Double.from(self) }

  /// The value as a `Bool`, or `nil` if conversion fails.
  ///
  /// Conversion rules:
  /// - `.bool(value)` returns the value directly
  /// - `.int(value)` returns true if > 0, false otherwise
  /// - `.double(value)` returns true if > 0.0, false otherwise
  /// - `.string(value)` parses "true", "yes", "on" as true; "false", "no", "off" as false (case-insensitive)
  public var boolValue: Bool? { try? Bool.from(self) }

  /// The value as a `String`, or `nil` if conversion fails.
  ///
  /// Conversion rules:
  /// - `.string(value)` returns the value directly
  /// - Other types return their string representation
  public var stringValue: String? { try? String.from(self) }
}
