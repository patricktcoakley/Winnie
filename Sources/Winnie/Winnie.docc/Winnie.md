# ``Winnie``

A Swift package for parsing and writing INI configuration files.

## Overview

Winnie provides a type-safe, Swift-friendly way to work with INI configuration files. The library follows general INI terminology: **sections** contain **options** with associated **values**. It supports reading and writing from both strings and files, and provides various APIs to manipulate sections and options.

## Key Features

- **Type Safety**: Automatic conversion between Swift types and INI values
- **Subscript Access**: Natural `parser["section", "option"]` syntax
- **Iteration Support**: Iterate over sections and option-value pairs
- **Comment Preservation**: Optional comment handling for round-trip fidelity
- **Customizable Formatting**: Configure spacing, assignment characters, and boolean formats
- **Error Handling**: Comprehensive error reporting with descriptive messages

## Usage Example

```swift
import Winnie

// Create parser and load configuration
let parser = ConfigParser()
try parser.addSection("database")

// Set values with automatic type conversion
parser["database", "host"] = "localhost"
parser["database", "port"] = 5432
parser["database", "ssl"] = true

// Read values with type safety
let host: String = try parser.getString(section: "database", option: "host")
let port: Int = try parser.getInt(section: "database", option: "port")

// Iterate over sections and options
for section in parser.sections {
  print("Section: \(section.section)")
  for (option, value) in section {
    print("  \(option) = \(value)")
  }
}
```

## Topics

### Getting Started

- ``ConfigParser``
- ``ConfigParserOptions``
- ``AssignmentCharacter``

### Working with Values

- ``INIValue``
- ``INIValueConvertible``

### Accessing Configuration Data

- ``SectionProxy``
- ``Section``
- ``SectionValues``
- ``SectionPair``

### Error Handling

- ``ConfigParserError``

### Advanced Features

- ``SectionProxySequence``
- ``SectionPairIterator``
- ``SectionProxyIterator``
