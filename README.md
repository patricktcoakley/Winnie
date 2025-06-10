# Winnie

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fpatricktcoakley%2FWinnie%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/patricktcoakley/Winnie)

An [INI file](https://en.wikipedia.org/wiki/INI_file)/config file parsing library inspired by [ConfigParser](https://docs.python.org/3/library/configparser.html) for Swift. Currently supports the [general featureset](#features) of ConfigParser with [more features planned in the future](#roadmap).

## INI Files

INI files are simple, structured configuration files that slot in nicely for situations when you need something to store some kind of configuration data but don't need or want the full overhead of something like JSON or YAML while giving you a bit of flexibility in how you structure your data. Some common real-world examples of INI files include Windows configuration files, such as [Desktop.ini](https://learn.microsoft.com/en-us/windows/win32/shell/how-to-customize-folders-with-desktop-ini), [Unreal Engine configuration files](https://dev.epicgames.com/documentation/en-us/unreal-engine/configuration-files-in-unreal-engine), [systemd service files](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html), and [Desktop Entry files](https://specifications.freedesktop.org/desktop-entry-spec/latest/) for UNIX-like desktop environments, such as [KDE](https://kde.org).

Since INI is not formally standardized, there may be variations between implementations, but the general structure is ostensibly the same:

```ini
# comment
[Section]
option = value

[AnotherSection]
...
```

where `# comment` is an optional comment, `[Section]` is a section header that namespaces all of its content, and `option = value` is a key-value pair. Possible value types include strings, numbers (integers and floats), and booleans. Aside from this, some semi-standardized features include supporting `=` and `:` for assignment, whitespace before and after the assignment character, and `;` and `#` for comments.

## Features

Winnie supports most of what ConfigParser does sans [interpolation](https://docs.python.org/3/library/configparser.html#interpolation-of-values) and more, including:

* The ability to read and write INI configs from strings and from files with  preservation of the original insertion order.
* The creating new configs from scratch.
* A customizable global fallback section when setting options without an explicit section.
* The ability to take references to sections and operate on them as if they were dictionaries.
* Safely-typed getters with the ability to provide default values and rely on type inference.
* Customizable section names, assignment characters, and padding for output.

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

// By default, the ConfigParser will use the following default options:
// Default section name is "DEFAULT"
// Assignment character is "="
// Leading and trailing spaces are both 1

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

// Initializing with a custom default section name,assignment character, and  padding
let opts = ConfigParserOptions(defaultSection: "GLOBAL", assignmentCharacter: .colon, leadingSpaces: 0, trailingSpaces: 4)
let customConfig = ConfigParser(opts)
try customConfig.set(option: "adminUser", value: "root") // Sets 'adminUser' in [GLOBAL] instead of the standard [DEFAULT]
let admin: String? = try? customConfig.get(option: "adminUser")

let customConfigOutput = customConfig.write()
// Prints:
// [GLOBAL]
// adminUser:    root
```

## Roadmap

At this point Winnie is pretty much feature-complete, and any of the following are going to be additive and more of a wishlist of things I would like to see added at some point in the future:

* It is a goal to eventually fully support more advanced INI types that Unreal Engine and others support, including arrays/lists, tuples, and structs.
* Investigate interpolation or other kinds of templating to make it easier to batch-create configs.
* Being able to preserve comments is currently not a goal per-se, as many similar libraries also don't do that, but it is also something I want to explore in the future as I could see it being beneficial to the end-user.
