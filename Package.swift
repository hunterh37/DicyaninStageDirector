// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "DicyaninStageDirector",
    platforms: [.visionOS(.v2), .macOS(.v14), .iOS(.v17)],
    products: [.library(name: "DicyaninStageDirector", targets: ["DicyaninStageDirector"])],
    targets: [
        .target(name: "DicyaninStageDirector"),
        .testTarget(name: "DicyaninStageDirectorTests", dependencies: ["DicyaninStageDirector"]),
    ],
    swiftLanguageModes: [.v5]
)
