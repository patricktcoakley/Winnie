# Winnie

An [INI](https://en.wikipedia.org/wiki/INI_file)/config file parsing library inpsired by [ConfigParser](https://docs.python.org/3/library/configparser.html) for Swift. Currently supports the general featureset of ConfigParser with [more features planned in the future](#roadmap).

## Features

Winnie supports most of what ConfigParser does sans [interpolation](https://docs.python.org/3/library/configparser.html#interpolation-of-values). This includes a the ability to read and write INI configs from strings and from files, to create new ones from scratch, a global fallback section when setting options without an explicit section, and the ability to take references to sections and operate on them as if they were dictionaries.

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
// You can use specific type getters or the generic get<T>
let name = try config.getString(section: "owner", option: "name")
let server: String = try config.get(section: "database", option: "server") // type inference
try config.set(section: "database", option: "file", value: "payroll_updated.data")

// Subscripting returns an optional INIValue? for safe value extraction
let portValue = config["database", "port"] // portValue is of type INIValue?
if let port = portValue?.intValue { // You can attempt to extract it using a typed getter
    print("Port as Int: \(port)")
}

// You can also safely use subscripting for assignment
config["database", "path"] = "/var/databasev2" // Assigns an INIValueConvertible

// You can write to a string or a file
let outputString = config.write() // Returns the INI content as a String (does not throw)
try config.writeFile("/tmp/database.ini") // Writes the INI content to a file path (throws)
```

## Roadmap

At this point Winnie is pretty much feature-complete, and any of the following are more of a wishlist of things I would like to see added at some point in the future:

* It is a goal to eventually fully support [Unreal Engine configuration files](https://dev.epicgames.com/documentation/en-us/unreal-engine/configuration-files-in-unreal-engine), which also has arrays, tuples, structs, and other primitives beyond what is usually available in the standard INI format.
* Adding more customization, such as naming the fallback section, adding tabs or spaces between entries, and casing for output (PascalCase vs camelCase vs snake_case).
* Investigate interpolation or other kinds of templating to make it easier to batch-create configs.
* Being able to preserve comments is not currently a goal per-se, as many similar libraries also don't do that, but it is also something I want to explore in the future as I could see it being beneficial to the end-user.
