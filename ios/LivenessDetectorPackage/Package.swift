// swift-tools-version:5.9
// LivenessDetector from the private Cloudsmith repository, as a Swift package.
// Copy this folder into your project and add it as a local package (File > Add Package
// Dependencies… > Add Local…), or host it in a git repository of your own.
//
// SwiftPM and Xcode authenticate the downloads with ~/.netrc (never commit the token):
//   machine dl.cloudsmith.io login token password <entitlement token>
// For a new SDK version, change `version`
// and both checksums (the SHA-256 of each zip, from the release's SHA256SUMS).
import PackageDescription

let version = "5.1.0"
let base = "https://dl.cloudsmith.io/basic/airookies/liveness-detector/raw/names"

func sdk(_ name: String, checksum: String) -> Target {
  .binaryTarget(name: name, url: "\(base)/\(name).xcframework/versions/\(version)/\(name).xcframework.zip",
                checksum: checksum)
}

let package = Package(
  name: "LivenessDetector",
  platforms: [.iOS(.v15)],
  products: [
    // Both frameworks: the Swift API and screen, and the engine with the models.
    .library(name: "LivenessDetector", targets: ["LivenessDetector", "LivenessCore"]),
  ],
  targets: [
    sdk("LivenessDetector", checksum: "d23727e6b7ec7b9a7f8ff32a7d0c0f304008931cdf3a9810c4408ceb952af436"),
    sdk("LivenessCore", checksum: "4787980e5e498cd57d5ff350c39e6df6ea22ba2114c33a8b161797fbe0007ef2"),
  ]
)
