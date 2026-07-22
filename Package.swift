// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Winnie",
  platforms: [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "Winnie",
      targets: ["Winnie"]
    )
  ],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-collections.git", .upToNextMajor(from: "1.1.4")
    )
  ],
  targets: [
    .target(
      name: "Winnie",
      dependencies: [
        .product(name: "Collections", package: "swift-collections")
      ]
    ),
    .testTarget(
      name: "WinnieTests",
      dependencies: ["Winnie"]
    ),
  ]
)
