// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TakeMi",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TakeMi", targets: ["TakeMi"])
    ],
    targets: [
        .executableTarget(
            name: "TakeMi",
            dependencies: [],
            path: "Sources/TakeMi",
            resources: [
                .process("Resources") 
            ]
        )
    ]
)
