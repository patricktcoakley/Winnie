// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Winnie",
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "Winnie",
      targets: ["Winnie"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.1.4")),
  ],
  targets: [
    .target(
      name: "Winnie", dependencies: [.product(name: "Collections", package: "swift-collections"),
      ]
    ),
    .testTarget(
      name: "WinnieTests",
      dependencies: ["Winnie"]
    ),
  ]
)
