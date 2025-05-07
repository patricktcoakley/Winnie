# Winnie

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpatricktcoakley%2FWinnie%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/patricktcoakley/Winnie)

An [INI](https://en.wikipedia.org/wiki/INI_file)/config file parsing library inpsired by [ConfigParser](https://docs.python.org/3/library/configparser.html) for Swift. Currently supports the [general featureset](#features) of ConfigParser with [more features planned in the future](#roadmap).

## Features

Winnie supports most of what ConfigParser does sans [interpolation](https://docs.python.org/3/library/configparser.html#interpolation-of-values) and some new features, including:

* The ability to read and write INI configs from strings and from files with  preservation of the original insertion order.
* The creating new configs from scratch.
* A customizable global fallback section when setting options without an explicit section.
* The ability to take references to sections and operate on them as if they were dictionaries.
* Safely-typed getters with the ability to provide default values and rely on type inference.
* Basic customization for writing out the config assignment operator to use or whether or not to include leading spaces.

## Usage

```swift
import Winnie

let input = """
[owner]
name = John Doe
organization = Acme Widgets Inc.

[database]
server = 192.0.2.62
port = 143
file = payroll.dat
path = /var/database
"""

let config = ConfigParser()

// You can read from strings or files
try config.read(input) // Reads from the string above
try config.readFile("/path/to/settings.ini") // Reads from a file path

// Winnie supports multiple ways to access sections, options, and values

// The get/set methods are marked as `throws`
// You can use typed getters or the generic get<T>
let name = try config.getString(section: "owner", option: "name")
try config.set(section: "database", option: "file", value: "payroll_updated.data")

let connectionRetries: Int = try config.get(section: "database", option: "retries", default: 3)
let autoConnect: Bool = try config.getBool(section: "database", option: "auto_connect", default: true)
let backupPath: String? = try? config.get(section: "archive", option: "path") // No default, will be nil if not found
let defaultLogLevel: String = try config.get(option: "log_level", default: "INFO") // Option from default section

// Subscripting returns an optional INIValue? for safe value extraction
let portValue = config["database", "port"] // portValue is of type INIValue?
if let port = portValue?.intValue { // You can attempt to extract it using a typed getter
    print("Port as Int: \(port)")
}

// Accessing a section and iterating its options and values
if let ownerSection = config["database"] {
    for (key, value) in ownerSection {
        print("\(key) is \(value)")
    }
}

// You can also safely use subscripting for assignment
config["database", "path"] = "/var/databasev2" // Assigns an INIValueConvertible

// You can write to a string or a file
let outputString = config.write() // Returns the INI content as a String (does not throw)
try config.writeFile("/tmp/database.ini") // Writes the INI content to a file path (throws)

// Initializing with a custom default section name
let customConfig = ConfigParser(defaultSection: "GLOBAL")
try customConfig.set(option: "adminUser", value: "root") // Sets 'adminUser' in [GLOBAL] instead of the standard [DEFAULT]
let admin: String? = try? customConfig.get(option: "adminUser")

// Overriding the default assignment with `:` and not including leading spaces
let customConfigOutput = customConfig.write(assignment: .colon, leadingSpaces: false)
```

## Roadmap

At this point Winnie is pretty much feature-complete, and any of the following are more of a wishlist of things I would like to see added at some point in the future:

* It is a goal to eventually fully support [Unreal Engine configuration files](https://dev.epicgames.com/documentation/en-us/unreal-engine/configuration-files-in-unreal-engine), which also has arrays, tuples, structs, and other primitives beyond what is usually available in the usual INI format (INI has no official standard).
* Adding more customization like specifying tabs or spaces between entries, casing for output (PascalCase vs camelCase vs snake_case), and default values for booleans (currently "True" and "False").
* Investigate interpolation or other kinds of templating to make it easier to batch-create configs.
* Being able to preserve comments is not currently a goal per-se, as many similar libraries also don't do that, but it is also something I want to explore in the future as I could see it being beneficial to the end-user.
