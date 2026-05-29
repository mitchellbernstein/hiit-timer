// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HIITTimer",
    platforms: [.iOS("26.1")],
    products: [
        .library(name: "HIITTimer", targets: ["HIITTimer"])
    ],
    targets: [
        .target(name: "HIITTimer")
    ]
)
