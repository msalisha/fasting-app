// swift-tools-version: 5.9
import PackageDescription

// All fasting logic that has no UI. Shared by the iPhone app, widgets and (later) the watch app,
// and unit-tested on every push.
let package = Package(
    name: "FastingCore",
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
    products: [
        .library(name: "FastingCore", targets: ["FastingCore"]),
    ],
    targets: [
        .target(name: "FastingCore"),
        .testTarget(name: "FastingCoreTests", dependencies: ["FastingCore"]),
    ]
)
