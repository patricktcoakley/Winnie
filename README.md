# Winnie

An [INI](https://en.wikipedia.org/wiki/INI_file) parsing library loosely based on [ConfigParser](https://docs.python.org/3/library/configparser.html) for Swift. Currently supports the general featureset of ConfigParser with [#roadmap](more features planned in the future).

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

// The get/set methods are marked as throws
// Use specific type getters or the generic get<T>
let name = try config.getString(section: "owner", option: "name")
let server: String = try config.get(section: "database", option: "server")

// Subscripting returns an optional INIValue? (nil if section/option doesn't exist)
let portValue = config["database", "port"] // portValue is of type INIValue?
if let port = portValue?.intValue {
    print("Port as Int: \(port)") // Access underlying value with .intValue, .stringValue, etc.
}

// Use the set method (throws)
try config.set(section: "database", option: "file", value: "payroll_updated.data")

// Use subscript assignment
config["database", "path"] = "/var/databasev2" // Assigns an INIValueConvertible

// You can write to a string or a file
let outputString = config.write() // Returns the INI content as a String (does not throw)
try config.writeFile("/tmp/database.ini") // Writes the INI content to a file path (throws)
```

## Roadmap

* It is a goal to eventually fully support [Unreal Engine configuration files](https://dev.epicgames.com/documentation/en-us/unreal-engine/configuration-files-in-unreal-engine), which also has arrays, structs, and other primitives beyond what is usually available in the standard INI format.
