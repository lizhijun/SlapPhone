// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SlapMac",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "SlapMac",
            path: "Sources",
            resources: [
                .copy("../Resources")
            ],
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("ServiceManagement"),
            ]
        )
    ]
)
