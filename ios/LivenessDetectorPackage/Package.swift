// swift-tools-version:5.9
import PackageDescription

let package = Package(
  name: "LivenessDetector",
  platforms: [.iOS(.v15)],
  products: [
    .library(name: "LivenessDetector", targets: ["LivenessDetector", "LivenessCore"]),
  ],
  targets: [
    .binaryTarget(name: "LivenessDetector", path: "LivenessDetector.xcframework"),
    .binaryTarget(name: "LivenessCore", path: "LivenessCore.xcframework"),
  ]
)
