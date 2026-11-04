// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SagaceData",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "SagaceData", targets: ["SagaceData"]),
    ],
    dependencies: [
        .package(path: "../SagaceCore"),
    ],
    targets: [
        .target(name: "SagaceData", dependencies: ["SagaceCore"]),
        .testTarget(name: "SagaceDataTests", dependencies: ["SagaceData"]),
    ]
)
