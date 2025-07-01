import Foundation
import Testing

@testable import Winnie

struct INIValueTests {
  // MARK: - Initialization Tests

  @Test func testINIValueFromString() {
    let intValue = INIValue(from: "42")
    #expect(intValue == .int(42))

    let doubleValue = INIValue(from: "3.14")
    #expect(doubleValue == .double(3.14))

    let boolTrueValue = INIValue(from: "true")
    #expect(boolTrueValue == .bool(true))

    let boolFalseValue = INIValue(from: "false")
    #expect(boolFalseValue == .bool(false))

    let stringValue = INIValue(from: "hello world")
    #expect(stringValue == .string("hello world"))
  }

  @Test func testINIValueBooleanVariations() {
    let boolTestCases: [(String, Bool)] = [
      ("true", true),
      ("yes", true),
      ("on", true),
      ("TRUE", true),
      ("YES", true),
      ("On", true),
      ("false", false),
      ("no", false),
      ("off", false),
      ("FALSE", false),
      ("NO", false),
      ("Off", false),
    ]

    for (input, expected) in boolTestCases {
      let value = INIValue(from: input)
      #expect(value == .bool(expected), "Input '\(input)' should be \(expected)")
    }

    #expect(INIValue(from: "1") == .int(1))
    #expect(INIValue(from: "0") == .int(0))
  }

  @Test func testINIValueNumericParsing() {
    #expect(INIValue(from: "-42") == .int(-42))
    #expect(INIValue(from: "999999") == .int(999999))

    #expect(INIValue(from: "0.0") == .double(0.0))
    #expect(INIValue(from: "-3.14159") == .double(-3.14159))
    #expect(INIValue(from: "2.5e10") == .double(2.5e10))
  }

  // MARK: - Computed Properties Tests

  @Test func testINIValueComputedProperties() {
    let intValue = INIValue.int(42)
    #expect(intValue.intValue == 42)
    #expect(intValue.stringValue == "42")
    #expect(intValue.doubleValue == 42.0)
    #expect(intValue.boolValue == true)

    let zeroValue = INIValue.int(0)
    #expect(zeroValue.boolValue == false)

    let stringValue = INIValue.string("hello")
    #expect(stringValue.stringValue == "hello")
    #expect(stringValue.intValue == nil)
    #expect(stringValue.doubleValue == nil)

    let boolValue = INIValue.bool(true)
    #expect(boolValue.boolValue == true)
    #expect(boolValue.intValue == 1)
    #expect(boolValue.doubleValue == 1.0)
    #expect(boolValue.stringValue == "True")

    let finiteDouble = INIValue.double(3.14)
    #expect(finiteDouble.intValue == 3)
  }

  @Test func testINIValueNilConversions() {
    let stringValue = INIValue.string("not a number")
    #expect(stringValue.intValue == nil)
    #expect(stringValue.doubleValue == nil)
    #expect(stringValue.boolValue == nil)

    let invalidBoolString = INIValue.string("maybe")
    #expect(invalidBoolString.boolValue == nil)
  }

  // MARK: - INIValueConvertible Tests

  @Test func testINIValueIntoConversion() {
    let stringValue = "test"
    let stringINI = stringValue.into()
    #expect(stringINI == .string("test"))

    let intValue = 42
    let intINI = intValue.into()
    #expect(intINI == .int(42))

    let doubleValue = 3.14
    let doubleINI = doubleValue.into()
    #expect(doubleINI == .double(3.14))

    let boolValue = true
    let boolINI = boolValue.into()
    #expect(boolINI == .bool(true))
  }

  @Test func testINIValueFromConversion() throws {
    // String conversion
    let stringResult: String = try String.from(.string("hello"))
    #expect(stringResult == "hello")

    let intToString: String = try String.from(.int(42))
    #expect(intToString == "42")

    // Int conversion
    let intResult: Int = try Int.from(.int(42))
    #expect(intResult == 42)

    let stringToInt: Int = try Int.from(.string("99"))
    #expect(stringToInt == 99)

    // Bool conversion
    let boolResult: Bool = try Bool.from(.bool(true))
    #expect(boolResult == true)

    let stringToBool: Bool = try Bool.from(.string("yes"))
    #expect(stringToBool == true)

    // Double conversion
    let doubleResult: Double = try Double.from(.double(3.14))
    #expect(doubleResult == 3.14)

    let intToDouble: Double = try Double.from(.int(42))
    #expect(intToDouble == 42.0)
  }

  @Test func testINIValueConversionErrors() {
    #expect(throws: ConfigParserError.self) {
      let _: Int = try Int.from(.string("not a number"))
    }

    #expect(throws: ConfigParserError.self) {
      let _: Double = try Double.from(.string("not a number"))
    }

    #expect(throws: ConfigParserError.self) {
      let _: Bool = try Bool.from(.string("maybe"))
    }
  }

  // MARK: - Edge Cases

  @Test func testINIValueSpecialDoubleValues() {
    let infValue = INIValue(from: "inf")
    #expect(infValue == .double(.infinity))

    let negInfValue = INIValue(from: "-inf")
    #expect(negInfValue == .double(-.infinity))

    let nanValue = INIValue(from: "nan")
    if case let .double(nan) = nanValue {
      #expect(nan.isNaN)
    } else {
      #expect(Bool(false), "Expected NaN double value")
    }
  }

  @Test func testINIValueStringFallback() {
    let complexString = INIValue(from: "user@example.com")
    #expect(complexString == .string("user@example.com"))

    let pathString = INIValue(from: "/path/to/file.txt")
    #expect(pathString == .string("/path/to/file.txt"))

    let alphanumeric = INIValue(from: "abc123def")
    #expect(alphanumeric == .string("abc123def"))
  }
}
