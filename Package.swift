// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "QuickDictateMac",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "QuickDictateMac",
            targets: ["QuickDictateMac"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "QuickDictateMac",
            path: "Sources/QuickDictateMac"
        ),
    ]
)
