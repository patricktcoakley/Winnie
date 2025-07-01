/// A protocol for types that can be converted to and from `INIValue`.
///
/// Types conforming to `INIValueConvertible` can be used directly with `ConfigParser`
/// methods, providing automatic conversion between Swift types and INI values.
///
/// ## Built-in Conformance
///
/// The following types already conform to `INIValueConvertible`:
/// - `String`
/// - `Int`
/// - `Double`
/// - `Bool`
/// - `INIValue`
///
/// ## Custom Conformance
///
/// ```swift
/// extension URL: INIValueConvertible {
///   public func into() -> INIValue {
///     return .string(self.absoluteString)
///   }
///
///   public static func from(_ value: INIValue) throws -> URL {
///     guard let string = value.stringValue,
///           let url = URL(string: string) else {
///       throw ConfigParserError.valueError("Invalid URL: \(value)")
///     }
///     return url
///   }
/// }
/// ```
public protocol INIValueConvertible {
  /// Converts this value to an `INIValue`.
  func into() -> INIValue

  /// Creates an instance of this type from an `INIValue`.
  ///
  /// - Parameter value: The `INIValue` to convert from.
  /// - Returns: An instance of the conforming type.
  /// - Throws: `ConfigParserError` if the conversion fails.
  static func from(_ value: INIValue) throws(ConfigParserError) -> Self
}
