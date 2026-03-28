// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SlapPhoneCore",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
        .macOS(.v14)
    ],
    products: [
        .library(name: "SlapPhoneCore", targets: ["SlapPhoneCore"])
    ],
    targets: [
        .target(
            name: "SlapPhoneCore",
            path: "Sources/SlapPhoneCore"
        )
    ]
)
