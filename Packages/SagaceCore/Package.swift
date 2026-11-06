// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SagaceCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "SagaceCore", targets: ["SagaceCore"]),
    ],
    targets: [
        .target(name: "SagaceCore"),
        .testTarget(name: "SagaceCoreTests", dependencies: ["SagaceCore"]),
    ]
)
