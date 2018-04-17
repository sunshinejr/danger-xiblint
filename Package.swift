// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "DangerXiblint",
    products: [
        .library(
            name: "DangerXiblint",
            targets: ["DangerXiblint"]),
    ],
    dependencies: [
        .package(url: "https://github.com/danger/danger-swift.git", from: "0.3.0")
    ],
    targets: [
        .target(
            name: "DangerXiblint",
            dependencies: ["Danger"]),
        .testTarget(
            name: "DangerXiblintTests",
            dependencies: ["DangerXiblint"]),
    ]
)