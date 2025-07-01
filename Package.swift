// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Winnie",
  products: [
    .library(
      name: "Winnie",
      targets: ["Winnie"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.1.4")),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
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
