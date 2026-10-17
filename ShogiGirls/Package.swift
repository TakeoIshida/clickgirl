// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "ShogiGirls", platforms: [.macOS(.v13), .iOS(.v16)], products: [.library(name: "ShogiCore", targets: ["ShogiCore"]), .executable(name:"ShogiBench",targets:["ShogiBench"])], targets: [.target(name: "ShogiCore"), .executableTarget(name:"ShogiBench",dependencies:["ShogiCore"]), .testTarget(name: "ShogiCoreTests", dependencies: ["ShogiCore"])])
