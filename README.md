# Winnie

An [INI](https://en.wikipedia.org/wiki/INI_file) parsing library based on [ConfigParser](https://docs.python.org/3/library/configparser.html) for Swift. Currently supports the general featureset of ConfigParser except subscripting, interpolation, and proxies, which are non-goals for the time being.

## Roadmap

It is a goal to eventually fully support [Unreal Engine configuration files](https://dev.epicgames.com/documentation/en-us/unreal-engine/configuration-files-in-unreal-engine), which also has arrays, structs, and other primitives beyond what is usually available in the standard INI format.
