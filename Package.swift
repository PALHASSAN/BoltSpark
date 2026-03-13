// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "BoltSpark",
    platforms: [
        .iOS(.v17), .macOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BoltSpark",
            targets: ["BoltSpark"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.0.0"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0"),
        .package(url: "https://github.com/PALHASSAN/LiveValidate.git", from: "0.2.3"),
    ],
    targets: [
        .macro(
            name: "BoltSparkMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "BoltSpark",
            dependencies: [
                "BoltSparkMacros",
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "LiveValidate", package: "LiveValidate")
            ]
        ),
        
        .testTarget(
            name: "BoltSparkTests",
            dependencies: ["BoltSpark"]
        ),
    ]
)
