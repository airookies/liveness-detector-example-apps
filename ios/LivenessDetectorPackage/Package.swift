// swift-tools-version:5.9
// LivenessDetector from the private Cloudsmith repository, as a Swift package.
// Copy this folder into your project and add it as a local package (File > Add Package
// Dependencies… > Add Local…), or host it in a git repository of your own.
//
// SwiftPM and Xcode authenticate the downloads with ~/.netrc (never commit the token):
//   machine dl.cloudsmith.io login token password <entitlement token>
// Replace ORG/REPO with the slugs you were given. For a new SDK version, change `version`
// and both checksums (the SHA-256 of each zip, from the release's SHA256SUMS).
import PackageDescription

let version = "5.0.0"
let base = "https://dl.cloudsmith.io/basic/ORG/REPO/raw/names"

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
    sdk("LivenessDetector", checksum: "12d8d86c9da99dbba9413cc588a7e8f58ab34c380e8a150fa9f1f3d2358a02ca"),
    sdk("LivenessCore", checksum: "ca2c7cb48cf145fde49dc60dfc1c51255fe2c5ea6c290bfcba1ce98f6d4c2c03"),
  ]
)
