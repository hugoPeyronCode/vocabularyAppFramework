// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SagaceUI",
    defaultLocalization: "fr",
    platforms: [.iOS(.v18)],
    products: [
        .library(name: "SagaceUI", targets: ["SagaceUI"]),
    ],
    dependencies: [
        .package(path: "../SagaceCore"),
    ],
    targets: [
        .target(
            name: "SagaceUI",
            dependencies: ["SagaceCore"],
            resources: [.process("Resources")]
        ),
        .testTarget(name: "SagaceUITests", dependencies: ["SagaceUI"]),
    ]
)
